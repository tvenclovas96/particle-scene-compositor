using Godot;
using System;

namespace ParticleCompositor;

/// <summary>
/// Synchronization hub node that starts and tracks all child <see cref="CpuParticles2D"/>.
/// It will detect any <see cref="CpuParticles2D"/> if it is their ancestor in the tree; they do not need
/// to be direct children of this node. Non-compatible node types are ignored.
/// 
/// <para> By default, automatically starts on <see cref="Node._Ready"/>, and frees itself when finished. </para>
/// </summary>
[GlobalClass, Icon("res://addons/particle_scene_compositor/sync_node_2d_csharp/cpu_particles/Cpu2d.svg")]
public partial class CpuSyncNode2dCs : Node2D
{
    /// <summary>
    /// If <see langword="true"/>, the node will automatically start all child <see cref="CpuParticles2D"/> on ready
    /// </summary>
    [Export] public bool Autostart { get; set; } = true;

    /// <summary>
    /// If <see langword="true"/>, all child <see cref="CpuParticles2D"/> will emit only once. Otherwise,
    /// they will loop and restart once all <see cref="CpuParticles2D"/> have finished or <see cref="TimeToFinish"/>
    /// is reached.
    /// </summary>
    [Export] public bool OneShot { get; set; } = true;

    /// <summary>
    /// If <see langword="true"/>, the node will free itself it has finished.
    /// </summary>
    [Export] public bool FreeOnFinish { get; set; } = true;

    /// <summary>
    /// if greater than 0, the node will finish once the elapsed emission time is equal
    /// to this value or higher. Otherwise, it will finish once all child <see cref="CpuParticles2D"/>
    /// emit their <see cref="CpuParticles2D.Finished"/> signals. Finishing will stop any ongoing child
    /// <see cref="CpuParticles2D"/> emissions.
    /// 
    /// <para> Useful when subemitters are used, since their <see cref="CpuParticles2D.Finished"/>
    /// signal is fired before all of their particles are cleared </para>
    /// </summary>
    [Export(PropertyHint.Range, "0, 10, 0.1, or_greater")]
    public float TimeToFinish
    {
        get => _timeToFinish != float.MaxValue ? _timeToFinish : 0f;
        set
        {
            if (value > 0f) _timeToFinish = value;
            else _timeToFinish = float.MaxValue;
        }
    }
    private float _timeToFinish = float.MaxValue;
    /// <summary>
    /// is <see langword="true"/> if any child <see cref="CpuParticles2D"/> is currently emitting
    /// </summary>
    public bool Emitting { get; private set; } = false;

    /// <summary>
    /// <see langword="true"/> if the node is currently active and not stopped.
    /// 
    /// <para> Note: If <see cref="TimeToFinish"/> is not 0 this may be <see langword="true"/>
    /// while no child <see cref="CpuParticles2D"/> are currently emitting.</para>
    /// </summary>
    public float TimeElapsed { get; private set; } = 0f;

    private int counter = 0;

    /// <summary>
    /// Emitted if <see cref="OneShot"/> is <see langword="true"/> and all child <see cref="CpuParticles2D"/>
    /// have finished or when <see cref="TimeToFinish"/> is reached. This is emitted right after
    /// <see cref="LoopFinished"/>. <para> If <see cref="FreeOnFinish"/> is set to <see langword="true"/>,
    /// the node will free itself after emitting this signal </para>
    /// </summary>
    public Action Finished;
    /// <summary>
    /// Emitted after all child <see cref="CpuParticles2D"/> emit their <see cref="CpuParticles2D.Finished"/> signal
    /// if <see cref="TimeToFinish"/> is set to 0. Otherwise, it is emitted when the elapsed emission time reaches
    /// <see cref="TimeToFinish"/>. <see cref="OneShot"/> does not affect this signal
    /// </summary>
    public Action LoopFinished;

    /// <summary>
    /// Starts all child <see cref="CpuParticles2D"/>. Automatically called on <see cref="_Ready"/> if autostart is enabled.
    /// Returns if already emitting.
    /// <para> Optional <see cref="preprocess"/> parameter can be passed to advance all effects from emission start,
    /// such as when loading a saved game state </para>
    /// </summary>
    /// <param name="preprocess"></param>
    public void Start(float preprocess = 0f)
    {
        if (Emitting) return;

        TimeElapsed = preprocess;
        foreach (Node child in GetChildren())
        {
            RecursiveActivate(child, preprocess);
        }
        Emitting = true;
    }

    /// <summary>
    /// Restarts all child <see cref="CpuParticles2D"/>, interrupting any in-progress emissions.
    /// Any newly added child <see cref="CpuParticles2D"/> nodes will be automatically included.
    /// <para> Optional <see cref="preprocess"/> parameter can be passed to advance all effects from emission start,
    /// such as when loading a saved game state </para>
    /// </summary>
    /// <param name="preprocess"></param>
    public void Restart(float preprocess = 0f)
    {
        counter = 0;
        TimeElapsed = preprocess;
        foreach (Node child in GetChildren())
        {
            RecursiveRestart(child, preprocess);
        }
        Emitting = true;
    }

    /// <summary>
    /// Stops all child <see cref="CpuParticles2D"/> emissions, interrupting any in-progress emissions.
    /// Does not cause the <see cref="Finished"/> or <see cref="LoopFinished"/> signals to be emitted.
    /// </summary>
    public void Stop()
    {
        counter = 0;
        foreach (Node child in GetChildren())
        {
            RecursiveStop(child);
        }
        Emitting = false;
    }

    public override void _Ready()
    {
        if (Autostart) Start();
    }

    public override void _Process(double delta)
    {
        if (!Emitting) return;

        TimeElapsed += (float)delta;
        if (TimeElapsed >= _timeToFinish)
        {
            Stop();
            Complete();
        }
    }

    private static void Activate(CpuParticles2D particles)
    {
        particles.OneShot = true;
        particles.Emitting = true;
        particles.Restart();
    }
    private static void RecursiveStop(Node node)
    {
        if (node is CpuParticles2D particles) particles.Emitting = false;
        foreach (Node child in node.GetChildren())
        {
            RecursiveStop(child);
        }
    }

    private void RecursiveActivate(Node node, float preprocess = 0f)
    {
        if (node is CpuParticles2D particles)
        {
            particles.Preprocess = preprocess;
            Activate(particles);
            particles.Finished += Decrement;
        }
        {
            foreach (Node child in node.GetChildren())
            {
                RecursiveActivate(child, preprocess);
            }
        }
    }

    private void RecursiveRestart(Node node, float preprocess)
    {
        if (node is CpuParticles2D particles)
        {
            particles.Preprocess = preprocess;
            Activate(particles);
            if (!IsConnected(CpuParticles2D.SignalName.Finished, Callable.From(Decrement)))
                particles.Finished += Decrement;
        }
        {
            foreach (Node child in node.GetChildren())
            {
                RecursiveRestart(child, preprocess);
            }
        }
    }

    private void Decrement()
    {
        counter--;
        if (counter <= 0 && TimeToFinish == 0f)
            Complete();
    }

    private void Complete()
    {
        Emitting = false;

        LoopFinished?.Invoke();
        if (!OneShot)
            Restart();
        else
        {
            Finished?.Invoke();
            if (FreeOnFinish)
                QueueFree();
        }
    }
}
