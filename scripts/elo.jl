using JSON3
using Dates

data_dir = joinpath(@__DIR__, "..", "data")
sessions = JSON3.read(read(joinpath(data_dir, "sessions.json"), String))

ratings = Dict{String,Float64}()
games_played = Dict{String,Int}()
hist = Vector{Dict{String,Any}}()

function getr(p)
    get!(ratings, p, 1500.0)
end

function updater!(a, b, Sa; K=32.0)
    Ra = getr(a)
    Rb = getr(b)
    Ea = 1 / (1 + 10^((Rb - Ra)/400))
    Ra2 = Ra + K * (Sa - Ea)
    Eb = 1 - Ea
    Sb = 1 - Sa
    Rb2 = Rb + K * (Sb - Eb)
    ratings[a] = Ra2
    ratings[b] = Rb2
end

function record_hist(date, sid)
    for (p, r) in ratings
        push!(hist, Dict("date"=>date, "player"=>p, "rating"=>r, "games_played"=>get(games_played, p, 0), "session_id"=>sid))
    end
end

for s in sessions
    date = s["date"]
    sid = s["session_id"]
    parts = Vector{String}(s["participants"])
    ranks = Vector{Int}(s["ranks"])
    n = length(parts)
    for p in parts
        games_played[p] = get(games_played, p, 0) + 1
    end
    K = 32.0 / max(n - 1, 1)
    for i in 1:n-1
        for j in i+1:n
            ri = ranks[i]
            rj = ranks[j]
            if ri < rj
                updater!(parts[i], parts[j], 1.0; K=K)
            elseif ri > rj
                updater!(parts[i], parts[j], 0.0; K=K)
            else
                updater!(parts[i], parts[j], 0.5; K=K)
            end
        end
    end
    record_hist(date, sid)
end

elo_dir = joinpath(data_dir, "elo")
isdir(elo_dir) || mkpath(elo_dir)

ratings_out = [Dict("player"=>p, "rating"=>round(r; digits=2), "games_played"=>get(games_played,p,0)) for (p,r) in sort(collect(ratings); by=x->-x[2])]

open(joinpath(elo_dir, "ratings.json"), "w") do io
    JSON3.write(io, ratings_out)
end

open(joinpath(elo_dir, "history.json"), "w") do io
    JSON3.write(io, hist)
end
