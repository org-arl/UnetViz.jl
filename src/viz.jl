using GLMakie

"""
    showtrace(trace; yaxis=:step, Δt=0.001, fontsize=20, windowsize=(2000,1500))
    showtrace(traces, i; yaxis=:step, Δt=0.001, fontsize=20, windowsize=(2000,1500))

Vizualize a trace. `i` is the trace number, if multiple trace groups are passed in.
The trace may be a loaded trace (see `load`), or a filename.

The `yaxis` can be either `:step` or `:time`. The `Δt` parameter controls the
spacing between displayed events on the y-axis, if they occur at the same time.
"""
function showtrace(trace::Group; yaxis=:step, Δt=0.001, fontsize=20, windowsize=(2000,1500))
  yaxis ∈ [:time, :step] || error("Invalid yaxis: $yaxis (should be :time or :step)")
  lifelines = Tuple{String,String,Bool}[]
  for n ∈ unique([e.node for e in trace.events])
    as = unique([e.agent for e in trace.events if e.node == n])
    for (i, a) ∈ enumerate(as)
      push!(lifelines, (n, a, i == 1))
    end
  end
  fap = vlines(1:length(lifelines); color=:black, axis=(ylabel=yaxis === :time ? "Time (s)" : "Time step",),
    inspector_label = (self, i, p) -> lifelines[i÷2][2] * "/" * lifelines[i÷2][1], figure=(resolution=windowsize,))
  fap.axis.xaxisposition = :top
  fap.axis.xticks = 1:length(lifelines)
  fap.axis.xtickformat = xs -> [l[3] ? "$(l[1])\n$(l[2])" : "<\n$(l[2])" for l ∈ lifelines]
  xs = Float64[]
  ys = Float64[]
  us = Float64[]
  labels = String[]
  stimuli = Dict{String,Float64}()
  t0 = (-1.0, -1.0)
  for (i, e) ∈ enumerate(trace.events)
    ll1 = findfirst(l -> l[1] == e.node && l[2] == e.agent, lifelines)
    if ll1 !== nothing
      ll2 = findfirst(l -> l[1] == e.node && l[2] == e.response.recipient, lifelines)
      t = yaxis === :time ? e.time/1000 : i
      t == t0[1] && (t = t0[2] + Δt)
      t0 = (e.time/1000, t)
      stimuli[e.response.id] = t
      if ll2 === nothing || ll1 == ll2
        ndx = findall(e1 -> e1.stimulus !== nothing && e1.stimulus.id == e.response.id, trace.events)
        if isempty(ndx)
          push!(xs, ll1)
          push!(ys, t)
          push!(us, 0.2)
          s = "$(e.response.id)\n$(e.response) ≫ $(e.response.recipient)"
          if e.stimulus !== nothing && e.stimulus.id != e.response.id
            s *= "\ndue to:\n$(e.stimulus.id)\n$(e.stimulus)"
          end
          push!(labels, s)
          text!(ll1 + 0.1, t; text="$(i): $(e.response)", inspectable=false, fontsize)
        else
          for j ∈ ndx
            ll2 = findfirst(l -> l[1] == trace.events[j].node && l[2] == trace.events[j].agent, lifelines)
            if ll1 != ll2
              push!(xs, ll1)
              push!(ys, t)
              push!(us, ll2-ll1)
              s = "$(e.response.id)\n$(e.response)"
              if e.stimulus !== nothing && e.stimulus.id != e.response.id
                s *= "\ndue to:\n$(e.stimulus.id)\n$(e.stimulus)"
              end
              push!(labels, s)
              text!((ll1 + ll2) / 2, t; text="$(i): $(e.response)", inspectable=false, fontsize)
            end
          end
        end
      else
        push!(xs, ll1)
        push!(ys, t)
        push!(us, ll2-ll1)
        s = "$(e.response.id)\n$(e.response)"
        if e.stimulus !== nothing && e.stimulus.id != e.response.id
          s *= "\ndue to:\n$(e.stimulus.id)\n$(e.stimulus)"
        end
        push!(labels, s)
        text!((ll1 + ll2) / 2, t; text="$(i): $(e.response)", inspectable=false, fontsize)
      end
      if e.stimulus !== nothing
        t1 = get(stimuli, e.stimulus.id, nothing)
        if t1 === nothing
          push!(xs, ll1 - 0.2)
          push!(ys, t)
          push!(us, 0.2)
          push!(labels, "$(e.stimulus.id)\n$(e.stimulus.sender) ≫ $(e.stimulus)")
          text!(ll1 - 0.2, t; text="$(i)", inspectable=false, fontsize)
          stimuli[e.stimulus.id] = t
        else
          t1 == t || lines!([ll1, ll1 - 0.1, ll1], [t1, (t1 + t)/2, t]; color=:gray, inspectable=false)
        end
      end
    end
  end
  arrows!(xs, ys, us, zeros(size(us)); color=:blue, arrowsize=20.0,
    inspector_label = (self, i, p) -> labels[i])
  ylims!(-1, t0[2] + 1)
  fap.axis.yreversed = true
  fap.axis.xzoomlock = true
  fap.axis.xpanlock = true
  fap.axis.xrectzoom = false
  DataInspector(fap)
  fap
end

function showtrace(trace::Vector{Group}, i=nothing; kwargs...)
  length(trace) == 1 && i === nothing && (i = 1)
  i === nothing && error("Multiple traces found, please specify trace index")
  showtrace(trace[i]; kwargs...)
end

showtrace(filename::AbstractString; kwargs...) = showtrace(load(filename); kwargs...)
showtrace(filename::AbstractString, i; kwargs...) = showtrace(load(filename), i; kwargs...)
