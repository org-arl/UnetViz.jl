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
    for e2 ∈ ev2
      if "group" ∈ keys(e2)
        push!(ev1, e2)
      else
        aid, rest = split(e2["component"], "::")
        atype, node = split(rest, "/")
        e2s = get(e2, "stimulus", nothing)
        stimulus = e2s === nothing ? nothing : Message(
          e2s["messageID"],
          Symbol(e2s["performative"]),
          e2s["clazz"],
          get(e2s, "sender", nothing),
          e2s["recipient"]
        )
        e = Event(
          e2["time"],
          aid,
          atype,
          node,
          e2["threadID"],
          stimulus,
          Message(
            e2["response"]["messageID"],
            Symbol(e2["response"]["performative"]),
            e2["response"]["clazz"],
            get(e2["response"], "sender", nothing),
            e2["response"]["recipient"]
          )
        )
        push!(events, e)
      end
    end
    push!(rv, Group(group, events))
  end
  rv
end
