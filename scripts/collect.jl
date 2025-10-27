using YAML
using JSON3
using Dates
using Glob

base = joinpath(@__DIR__, "..", "src")
cands = filter(isdir, [joinpath(base, "content", "blog"), joinpath(base, "blog")])
globs = reduce(vcat, [glob("*.md", d) for d in cands])
out_dir = joinpath(@__DIR__, "..", "data")
isdir(out_dir) || mkpath(out_dir)

function parse_frontmatter(s::String)
    if startswith(s, "---") || startswith(s, "\ufeff---")
        m = match(r"^\ufeff?---\s*(?:\r?\n)(.*?)(?:\r?\n)---(?:\r?\n|$)"s, s)
        m === nothing && error("frontmatter block malformed")
        return YAML.load(String(m.captures[1]))
    else
        error("frontmatter not found")
    end
end

sessions = Vector{Dict{String,Any}}()
for f in sort(globs)
    text = read(f, String)
    y = parse_frontmatter(text)
    date = y["date"]
    title = y["title"]
    for g in y["games"]
        push!(sessions, Dict(
            "date" => date,
            "title" => title,
            "game" => g["name"],
            "session_id" => g["session_id"],
            "participants" => g["participants"],
            "ranks" => g["ranks"],
            "scores" => get(g, "scores", nothing),
            "ratings" => get(g, "ratings", nothing),
            "minutes" => get(g, "minutes", nothing),
            "source" => f
        ))
    end
end

open(joinpath(out_dir, "sessions.json"), "w") do io
    JSON3.write(io, sessions)
end
