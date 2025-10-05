using JSON3
using Dates
using Statistics

data_dir = joinpath(@__DIR__, "..", "data")
sessions_path = joinpath(data_dir, "sessions.json")
isfile(sessions_path) || error("sessions.json not found")
sessions = JSON3.read(read(sessions_path, String))

mutable struct Acc
    sum::Float64
    n::Int
    values::Vector{Float64}
    plays::Int
    first_date::Date
    last_date::Date
    by_player::Dict{String,Tuple{Float64,Int}}
end

function acc_init(d::Date)
    Acc(0.0, 0, Float64[], 0, d, d, Dict{String,Tuple{Float64,Int}}())
end

function acc_push!(a::Acc, date::Date, player::String, score::Float64)
    a.sum += score
    a.n += 1
    push!(a.values, score)
    if date < a.first_date
        a.first_date = date
    end
    if date > a.last_date
        a.last_date = date
    end
    tp = get(a.by_player, player, (0.0, 0))
    a.by_player[player] = (tp[1] + score, tp[2] + 1)
    a
end

function acc_play!(a::Acc)
    a.plays += 1
    a
end

by_game = Dict{String,Acc}()

for s in sessions
    date = Date(String(s["date"]))
    game = String(s["game"])
    if !haskey(by_game, game)
        by_game[game] = acc_init(date)
    end
    acc_play!(by_game[game])
    r = get(s, "ratings", nothing)
    if r !== nothing
        for (player, v) in pairs(r)
            acc_push!(by_game[game], date, String(player), Float64(v))
        end
    end
end

function medianf(v::Vector{Float64})
    isempty(v) && return NaN
    median(v)
end

out = Vector{Dict{String,Any}}()
for (game, a) in by_game
    avg = a.n == 0 ? NaN : a.sum / a.n
    med = medianf(a.values)
    per_player = Dict{String,Float64}()
    for (p, (s, n)) in a.by_player
        per_player[p] = n == 0 ? NaN : s / n
    end
    push!(out, Dict(
        "game" => game,
        "avg" => round(avg; digits=2),
        "median" => isnan(med) ? med : round(med; digits=2),
        "ratings_count" => a.n,
        "plays" => a.plays,
        "first_played" => string(a.first_date),
        "last_played" => string(a.last_date),
        "player_avg" => per_player
    ))
end

isdir(data_dir) || mkpath(data_dir)
open(joinpath(data_dir, "games.json"), "w") do io
    JSON3.write(io, out)
end
