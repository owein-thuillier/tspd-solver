using PyPlot
using CSV
using Dates
include("structures.jl")
include("utilitaires.jl")
include("parser.jl")
include("instance_sur_mesure.jl")
include("concorde.jl")
include("partitionnement_mono.jl")

function main()
    continuer = "o"
    while continuer == "o"
        # Remise à zéro de l'environnement
        reset()

        # Chargement instance
        #instance = test()
        instance = choixInstance()
        caracteristiquesInstance(instance)
        graphique = initGraphique(instance)

        # Résolution TSP
        resolutionConcorde(instance)
        affichageSolution(instance) 
        majGraphique(instance, graphique)

        # Choix mono/bi
        partitionnementMonoObjectif(instance)
        affichageSolution(instance) 
        majGraphique(instance, graphique)

        # Continuer
        continuer = choixBinaire("\n --> Souhaitez-vous continuer (o/n) ? ")
     end
     close()
end

main()

