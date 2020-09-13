########### Utilitaires ###########

function distance(p1, p2)
    # Retourne la distance (euclidienne) entre les deux points
    dx = abs(p1.x - p2.x)
    dy = abs(p1.y - p2.y)
    return sqrt(dx^2 + dy^2)
end

function creationDistancier(nbPoints, listePoints)
    D = Array{Float64,2}(undef, nbPoints, nbPoints)
    for i in 1:nbPoints
        for j in 1:nbPoints
            D[i,j] = distance(listePoints[i], listePoints[j])
        end
    end
    return D
end 

function coutTour(ordreVisite, instance)
    # Retourne le coût du tour passé en paramètre avec le distancier
    distance = 0
    for i in 1:size(ordreVisite,1)-1
        distance += instance.D[ordreVisite[i], ordreVisite[i+1]]
    end
    return (distance / instance.vitesseCamion)
end

########### Contrôles de saisie utilisateur ###########

function choixListe(borneSup, message=" --> Votre choix : ")
    # Permet de demander à l'utilisateur de faire un choix entre plusieurs items [[1, borneSup]]
    liste = []
    for i in 1:borneSup
        push!(liste, string(i))
    end

    choix = "-1"
    tentative = 1 
    while !(choix in liste) 
        # Tant que l'utilisateur ne saisit pas un numéro correct, on redemande
        if tentative == 1 # Première tentative
            print("\n")
            print(message)
        else
            print(message)
        end
        choix = readline()  
        tentative += 1
    end
    return choix
end

function choixBinaire(message)
    # Permet de demander à l'utilisateur de faire un choix binaire (oui ou non)
    choix = "-1"
    tentative = 1
    while choix != "o" && choix != "n"
        # Tant que l'utilisateur ne saisit pas une lettre correcte, on redemande
        if tentative == 1 # Première tentative
            print(message)
        else
            print(message)
        end
        choix = readline()  
        tentative += 1
    end
    return choix
end

########### Affichages ###########

function caracteristiquesInstance(instance)
    # Permet d'afficher les différents paramètres d'une instance
    println("\n========== Caractéristiques de l'instance ==========")
    println("\n Nombre de points (dépôt inclus) : " * string(instance.nbPoints))
    println(" Vitesse du camion : " * string(instance.vitesseCamion))
    println(" Vitesse du drone : " * string(instance.vitesseDrone) * "\n")
    choix = choixBinaire(" --> Souhaitez-vous afficher la liste des points (o/n) ? ")
    if choix == "o"
        println("\n  Liste des points :")
        println("  ------------------")
        for i in 1:instance.nbPoints
            println("    ", i, ") x = ", instance.listePoints[i].x, " | y = ", instance.listePoints[i].y)  
        end
        println("\n")
    end

    choix = choixBinaire(" --> Souhaitez-vous afficher le distancier (o/n) ? ")
    if choix == "o"
        println("\n  Distancier :")
        print("  ------------")
        for i in 1:instance.nbPoints
            print("\n    ")
            for j in 1:instance.nbPoints
                print(round(instance.D[i,j], digits=2), "  ")
            end
        end
        println("")
    end    
    println("\n========== Caractéristiques de l'instance ==========")
end

function affichageSolution(instance)
    println("\n========== Détail de la solution ==========\n")
    println("  Temps de parcours total : " * string(instance.solution.tempsParcours))
    println("  Temps d'attente total : " * string(instance.solution.tempsAttente))
    println("\n  Ordre de visite du camion : ")
    println("  --------------------------- \n")
    if length(instance.solution.ordreVisiteCamion) <= 10
        print("  ")
        for i in 1:length(instance.solution.ordreVisiteCamion)-1
            print(string(instance.solution.ordreVisiteCamion[i]) * " --> ")
        end
        println(string(instance.solution.ordreVisiteCamion[end]))
    else
        print("  ")
        for i in 1:9
            print(string(instance.solution.ordreVisiteCamion[i]) * " --> ")
        end
        print("... --> ")
        println(string(instance.solution.ordreVisiteCamion[end-1]) * " --> " * string(instance.solution.ordreVisiteCamion[end]))
        println("\n /!\\ Affichage partiel (trop de clients) /!\\")
    end
    
    if length(instance.solution.operationsDrone) != 0
        println("\n  Liste des opérations du drone : ")
        println("  ------------------------------- \n")
        op = instance.solution.operationsDrone
        if length(op) <= 10
            for i in 1:length(op)
                #println(" $i) Décollage : $(op[i][1]); Livraison : $(op[i][2]); Atterrissage : $(op[i][3])")
                println(" $i) $(op[i][1]) --drone--> $(op[i][2]) --drone--> $(op[i][3])")
            end
        else
            for i in 1:9
                #println(" $i) Décollage : $(op[i][1]); Livraison : $(op[i][2]); Atterrissage : $(op[i][3])")
                println(" $i) $(op[i][1]) --drone--> $(op[i][2]) --drone--> $(op[i][3])")
            end
            println(" ...") 
            println(" ...")
            println(" ...")
            println(" $(length(op))) $(op[(length(op))][1]) --drone--> $(op[(length(op))][2]) --drone--> $(op[(length(op))][3])")
            println("\n /!\\ Affichage partiel (trop d'opérations) /!\\")
        end
    end
    println("\n========== Détail de la solution ==========")
end

function initGraphique(instance)
    graphique = plt.figure() # Sortie graphique unique
    affichageGraphique(instance, graphique)
    return graphique
end

function majGraphique(instance, graphique)
    clf() # On supprime l'ancienne figure pour afficher la nouvelle
    affichageGraphique(instance, graphique)
end

function affichageGraphique(instance, fig=plt.figure(), animation=false, col="blue")
    # Affiche une solution de TSP, éventuellement juste les points si ordreVisite vide
    ax = fig.gca()
    if instance.codeResolution == 0
        #title("Localisation du dépôt et des clients")
        title(L"Customers and depot locations ($speed_{t} = $"*string(instance.vitesseCamion)*L", $speed_{d} = $"*string(instance.vitesseDrone)*")")
    elseif instance.codeResolution == 1
        #title("Solution optimale TSP - Concorde")
        title(L"TSP optimal solution - Concorde ($speed_{t} = $"*string(instance.vitesseCamion)*L", $speed_{d} = $"*string(instance.vitesseDrone)*")")
    elseif instance.codeResolution == 2
        #title("Solution admissible TSP - Lin-Kernighan")
        title(L"TSP solution - Lin-Kernighan ($speed_{t} = $"*string(instance.vitesseCamion)*L", $speed_{d} = $"*string(instance.vitesseDrone)*")")
    elseif instance.codeResolution == 3
        #title(L"Solution admissible TSP-D - AEP ($vitesse_{t} = $"*string(instance.vitesseCamion)*L", $vitesse_{d} = $"*string(instance.vitesseDrone)*")")
        title(L"TSP-D solution - A1 ($speed_{t} = $"*string(instance.vitesseCamion)*L", $speed_{d} = $"*string(instance.vitesseDrone)*")")
    elseif instance.codeResolution == 4
        #title(L"Solution admissible TSP-D - EP ($vitesse{t} = $"*string(instance.vitesseCamion)*L", $vitesse{d} = $"*string(instance.vitesseDrone)*")")
        title(L"TSP-D solution - A2 ($speed_{t} = $"*string(instance.vitesseCamion)*L", $speed_{d} = $"*string(instance.vitesseDrone)*")")
    elseif instance.codeResolution == 5
        #title(L"Solution admissible TSP-D - EP ($vitesse{t} = $"*string(instance.vitesseCamion)*L", $vitesse{d} = $"*string(instance.vitesseDrone)*")")
        title(L"TSP-D solution - 2A1 ($speed_{t} = $"*string(instance.vitesseCamion)*L", $speed_{d} = $"*string(instance.vitesseDrone)*")")
    end
    xlabel(L"x ($z_1 = $"*string(round(instance.solution.tempsParcours, digits=2))*L", $z_2 = $"*string(round(instance.solution.tempsAttente, digits=2))*")")
    ylabel("y")
    grid(true)
    xCoordClients = []
    yCoordClients = []
    #ax.plot(instance.listePoints[1].x, instance.listePoints[1].y, ls="", marker="x", color="green", label="Dépôt") 
    ax.plot(instance.listePoints[1].x, instance.listePoints[1].y, ls="", marker="x", color="green", label="Depot", picker=true) 
    for i in 2:instance.nbPoints
        push!(xCoordClients, instance.listePoints[i].x)
        push!(yCoordClients, instance.listePoints[i].y)
    end
    #ax.plot(xCoordClients, yCoordClients, ls="", marker="x", color="red", label="Clients") 
    ax.plot(xCoordClients, yCoordClients, ls="", marker="x", color="red", label="Customers", picker=true) 

    for i in 1:instance.nbPoints
        ax.text(instance.listePoints[i].x+1.5, instance.listePoints[i].y+1.5, instance.listePoints[i].id) 
    end         

    if instance.solution.ordreVisiteCamion != [] 
        plot(0, 0, linewidth=0.7, color="blue", label="Truck") # Pour forcer l'affichage de la légende
        for i in 2:size(instance.solution.ordreVisiteCamion,1)
            p1 = instance.listePoints[instance.solution.ordreVisiteCamion[i-1]]
            p2 = instance.listePoints[instance.solution.ordreVisiteCamion[i]]
            connecterPointsCamion(p1, p2, col)
            if animation == true
                pause(0.5)
            end
        end
    end

    if instance.solution.operationsDrone != []
        plot(0, 0, "--", linewidth=0.7, color="orange", label="Drone") # Pour forcer l'affichage de la légende
        for i in 1:size(instance.solution.operationsDrone,1)
            p1 = instance.listePoints[instance.solution.operationsDrone[i][1]]
            p2 = instance.listePoints[instance.solution.operationsDrone[i][2]]
            p3 = instance.listePoints[instance.solution.operationsDrone[i][3]]
            connecterPointsDrone(p1, p2) 
            if p3 != p1 # Si p3 == p1 alors il s'agit d'un aller-retour, on ne trace qu'un seul trait en pointillé
                connecterPointsDrone(p2, p3) 
            end
        end
    end
    legend(loc="best")
end

function connecterPointsCamion(p1, p2, col="blue")
    # Trace une ligne en trait plein entre deux points (clients) pour le camion
    plot([p1.x, p2.x], [p1.y, p2.y], linewidth=0.7, color=col)
end

function connecterPointsDrone(p1, p2) 
    # Trace une ligne en pointillé entre deux points pour le drone
    plot([p1.x, p2.x], [p1.y, p2.y], "--", linewidth=0.7, color="orange")
end

########### Reset ###########

function reset()
    close() # On ferme la figure courante
    run(`clear`) # On efface le contenu de la console
end

########### Etude vitesse ###########


