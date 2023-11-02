using JSON

"""
    load(filename)

Load a trace from a JSON file.
"""
function load(filename)
  json = JSON.parsefile(filename)
  get(json, "version", nothing) == "1.0" || error("Invalid trace version")
  get(json, "group", nothing) == "EventTrace" || error("Invalid trace format")
  ev1 = get(json, "events", nothing)
  ev1 isa Vector || error("No trace events found")
  rv = Group[]
  for e1 ∈ ev1
    group = e1["group"]
    ev2 = e1["events"]
    events = Event[]
    t0 = nothing
    for e2 ∈ ev2
      if "group" ∈ keys(e2)
        push!(ev1, e2)
      else
        aid, rest = split(e2["component"], "::")
        atype, node = split(rest, "/")
        e2s = get(e2, "stimulus", nothing)
        e2r = get(e2, "response", nothing)
        stimulus = e2s === nothing ? nothing : Message(
          e2s["messageID"],
          Symbol(e2s["performative"]),
          e2s["clazz"],
          get(e2s, "sender", nothing),
          e2s["recipient"]
        )
        response = e2r === nothing ? nothing : Message(
          e2r["messageID"],
          Symbol(e2r["performative"]),
          e2r["clazz"],
          get(e2r, "sender", nothing),
          e2r["recipient"]
        )
        t0 == nothing && (t0 = e2["time"])
        e = Event(
          e2["time"] - t0,
          aid,
          atype,
          node,
          e2["threadID"],
          stimulus,
          response,
          get(e2, "info", nothing)
        )
        push!(events, e)
      end
    end
    if length(events) > 0
      push!(rv, Group(group, t0, events))
    end
  end
  rv
end
