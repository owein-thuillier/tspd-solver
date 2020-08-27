mutable struct Point
    x::Float64 # Coordonnée x 
    y::Float64 # Coordonnée x 
    id::String # Identifiant
end

mutable struct Solution
    # Structure définissant une solution (TSP/TSP-D)
    ordreVisiteCamion::Vector{Int64}
    operationsDrone::Vector{Vector{Int64}}
    tempsParcours::Float64 # Temps de parcours total
    tempsAttente::Float64 # Temps d'attente total (drone + camion)
end

mutable struct Instance
    vitesseCamion::Float64
    vitesseDrone::Float64
    nbPoints::Int64
    listePoints::Vector{Point}
    D::Array{Float64,2} # Distancier
    solution::Solution
    codeResolution::Int64 # Permet de savoir quel est l'état courant de la résolution
    # 0 = Initialisation (càd. pas de résolution)
    # 1 = TSP : solution exacte 
    # 2 = TSP : solution approchée LK
    # 3 = TSP-D : AEP mono-objectif
    # 4 = TSP-D : EP mono-objectif
end
