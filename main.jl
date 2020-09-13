using PyPlot
using CSV
using Dates
include("structures.jl")
include("utilitaires.jl")
include("parser.jl")
include("instance_sur_mesure.jl")
include("concorde.jl")
include("partitionnement_mono.jl")
include("partitionnement_bi.jl")

function main()
    continuer = "o"
    while continuer == "o"
        # Remise à zéro de l'environnement
        reset()

        # Chargement instance
        instance = choixInstance()
        instance.vitesseCamion = 1
        instance.vitesseDrone = 3
        caracteristiquesInstance(instance)
        graphique = initGraphique(instance)

        # Résolution TSP
        resolutionConcorde(instance)
        affichageSolution(instance) 
        majGraphique(instance, graphique)

        # Choix mono/bi
        println("\n Choix du type de résolution (TSP-D) :")
        println(" -------------------------------------")
        println("  1) Mono-objectif")
        println("  2) Bi-objectif")
        choix = choixListe(2)
        if choix == "1"       
            partitionnementMonoObjectif(instance)
        elseif choix == "2"
            partitionnementBiObjectif(instance)
        end
        affichageSolution(instance) 
        majGraphique(instance, graphique)

        # Continuer
        continuer = choixBinaire("\n --> Souhaitez-vous continuer (o/n) ? ")
     end
     close()
end


main()









