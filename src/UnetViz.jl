module UnetViz

export showtrace

### data structures

struct Message
  id::String
  performative::Symbol
  msgtype::String
  sender::Union{String,Nothing}
  recipient::String
end

struct Event
  time::Int64
  agent::String
  agenttype::String
  node::String
  thread::String
  stimulus::Union{Message,Nothing}
  response::Message
end

struct Group
  name::String
  events::Vector{Event}
end

Base.show(io::IO, m::Message) = m.msgtype == "org.arl.fjage.Message" ? print(io, m.performative) : print(io, split(m.msgtype, r"[\.\$]")[end])
Base.show(io::IO, e::Event) = print(io, "[$(e.time)] $(e.agent)::$(split(e.agenttype, '.')[end])/$(e.node) $(e.stimulus) -> $(e.response)")
Base.show(io::IO, g::Group) = print(io, "$(g.name) ($(length(g.events)) events)")

### loading and plotting

include("trace.jl")
include("viz.jl")

end # module
