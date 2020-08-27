function choixInstance()
    println("\n Choix de la bibliothèque :")
    println(" --------------------------")
    println("  1) Agatz")
    println("  2) Poikonen")
    println("  3) Nous")
    println("  4) TSPLIB : all_tsp")
    println("  5) TSPLIB : vlsi")
    println("  6) TSPLIB : tnm")
    println("  7) Sur mesure")
    choix = choixListe(7)
    if choix == "1"
        instance = parserAgatz()
    elseif choix == "2"
        instance = parserPoikonen()
    elseif choix == "3"
        instance = parserNous()
    elseif choix == "4"
        instance = parserTSPLIB("all_tsp/")
    elseif choix == "5"
        instance = parserTSPLIB("vlsi/")
    elseif choix == "6"
        instance = parserTSPLIB("tnm/")
    elseif choix == "7"
        instance = instanceSurMesure()
    end
end

function test()
    # Parsing de l'instance
    f = open("instances/agatz/base/doublecenter-51-n10.txt")
    lignes = readlines(f) # Lecture de l'instance choisie
    vitesseCamion = parse(Float64, lignes[2])
    vitesseDrone = parse(Float64, lignes[4])
    nbPoints = parse(Int, lignes[6])
    listePoints = Vector{Point}(undef, nbPoints)
    xDepot, yDepot = parse.(Float64, split(lignes[8])[1:2])
    idDepot = "1"
    depot = Point(xDepot, yDepot, idDepot)
    listePoints[1] = depot
    compteur = 2
    for i in 10:length(lignes) # Pour tous les autres points
        xPoint, yPoint = parse.(Float64, split(lignes[i])[1:2])
        idPoint = string(compteur)
        point = Point(xPoint, yPoint, idPoint)
        listePoints[compteur] = point
        compteur += 1
    end
    close(f)
    D = creationDistancier(nbPoints, listePoints)

    # Création de l'instance
    solution = Solution([], [], 0, 0) # Solution vide pour le moment
    instance = Instance(vitesseCamion, vitesseDrone, nbPoints, listePoints, D, solution, 0)
    return instance
end

function parserAgatz()
    # Choix du type d'instance
    println("\n Choix du type d'instance :")
    println(" --------------------------")
    println("  1) Test ")
    println("  2) Uniforme ")
    println("  3) Simplement centrée ")
    println("  4) Doublement centrée ")
    choix1 = parse(Int64, choixListe(4))
    liste = ["base", "uniform", "singlecenter", "doublecenter"]
    listeInstances = readdir("instances/agatz/"*liste[choix1])

    # Choix de l'instance
    println("\n Liste des instances :")
    println(" ---------------------")
    for i in 1:length(listeInstances)
        println("   ",i,") ", listeInstances[i])
    end
    choix2 = parse(Int64, choixListe(length(listeInstances)))

    # Parsing de l'instance
    f = open("instances/agatz/"*liste[choix1]*"/"*listeInstances[choix2])
    lignes = readlines(f) # Lecture de l'instance choisie
    vitesseCamion = parse(Float64, lignes[2])
    vitesseDrone = parse(Float64, lignes[4])
    nbPoints = parse(Int, lignes[6])
    listePoints = Vector{Point}(undef, nbPoints)
    xDepot, yDepot = parse.(Float64, split(lignes[8])[1:2])
    idDepot = "1"
    depot = Point(xDepot, yDepot, idDepot)
    listePoints[1] = depot
    compteur = 2
    for i in 10:length(lignes) # Pour tous les autres points
        xPoint, yPoint = parse.(Float64, split(lignes[i])[1:2])
        idPoint = string(compteur)
        point = Point(xPoint, yPoint, idPoint)
        listePoints[compteur] = point
        compteur += 1
    end
    close(f)
    D = creationDistancier(nbPoints, listePoints)

    # Création de l'instance
    solution = Solution([], [], 0, 0) # Solution vide pour le moment
    instance = Instance(vitesseCamion, vitesseDrone, nbPoints, listePoints, D, solution, 0)
    return instance
end

function parserPoikonen()
    # Choix de la taille de l'instance
    println("\n Choix de la taille de l'instance :")
    println(" ----------------------------------")
    println("  1) 10 noeuds ")
    println("  2) 15 noeuds ")
    println("  3) 20 noeuds ")
    println("  4) 30 noeuds ")
    println("  5) 40 noeuds ")
    println("  6) 50 noeuds ")
    println("  7) 60 noeuds ")
    println("  8) 70 noeuds ")
    println("  9) 80 noeuds ")
    println("  10) 90 noeuds ")
    println("  11) 100 noeuds ")
    println("  12) 200 noeuds ")
    choix = parse(Int64, choixListe(12))
    liste = ["10_points", "15_points", "20_points", "30_points",
             "40_points", "50_points", "60_points", "70_points",
             "80_points", "90_points", "100_points", "200_points",]

    # Choix de l'instance
    lignes = CSV.read("instances/poikonen/instances_"*liste[choix]*".csv", header=false) #openquotechar='[', closequotechar=']')
    println("\n Nombre d'instances : " * string(size(lignes,1)))
    choix = parse(Int64, choixListe(size(lignes,1)))

    # Parsing de l'instance
    temp = lignes[choix,2] 
    temp = replace(temp, '['=>"")
    temp = split(temp[1:end-2], "],")
    nbPoints = length(temp)-1
    listePoints = Vector{Point}(undef, nbPoints)
    for i in 1:length(temp)-1
        couple = split(temp[i], ",")
        xPoint, yPoint = parse(Float64, couple[1]), parse(Float64, couple[2]) 
        idPoint = string(i)
        point = Point(xPoint, yPoint, idPoint)
        listePoints[i] = point
    end
    D = creationDistancier(nbPoints, listePoints)

    # Paramètres à renseigner manuellement
    println("\n========== Paramètres d'instance ==========")
    print("\n --> Vitesse du camion : ")
    vitesseCamion = parse(Float64, readline())
    print(" --> Vitesse du drone : " )
    vitesseDrone = parse(Float64, readline())
    println("\n========== Paramètres d'instance ==========")

    # Création de l'instance
    solution = Solution([], [], 0, 0) # Solution vide pour le moment
    instance = Instance(vitesseCamion, vitesseDrone, nbPoints, listePoints, D, solution, 0)
    return instance
end


function parserNous()
    # Choix de la taille de l'instance
    println("\n Choix de la taille de l'instance :")
    println(" ----------------------------------")
    println("  1) 10-100 noeuds")
    println("  2) 100-1000 noeuds")
    println("  3) Autres")
    choix1 = parse(Int64, choixListe(3))
    liste = ["10_100", "100_1000", "autres"]
    listeInstances = readdir("instances/nous/bibliotheque_"*liste[choix1])

    # Choix de l'instance
    println("\n Liste des instances :")
    println(" ---------------------")
    for i in 1:length(listeInstances)
        println("   ",i,") ", listeInstances[i])
    end
    choix2 = parse(Int64, choixListe(length(listeInstances)))

    # Parsing de l'instance
    f = open("instances/nous/bibliotheque_"*liste[choix1]*"/"*listeInstances[choix2]) 
    lignes = readlines(f) # Lecture de l'instance choisie
    nbPoints = parse(Int64, lignes[1])
    listePoints = Vector{Point}(undef, nbPoints)
    vitesseCamion, vitesseDrone = parse.(Float64, split(lignes[2]))
    compteur = 1
    for i in 3:length(lignes)
        xPoint, yPoint = parse.(Float64, split(lignes[i])[1:2])
        idPoint = string(compteur)
        point = Point(xPoint, yPoint, idPoint)
        listePoints[compteur] = point
        compteur += 1        
    end
    close(f)
    D = creationDistancier(nbPoints, listePoints)

    # Création de l'instance
    solution = Solution([], [], 0, 0) # Solution vide pour le moment
    instance = Instance(vitesseCamion, vitesseDrone, nbPoints, listePoints, D, solution, 0)
    return instance
end

function parserTSPLIB(librairie)
   # Choix de l'instance
    listeInstances = readdir("instances/tsplib/"*librairie)
    println("\n Liste des instances :")
    println(" ---------------------")
    for i in 1:length(listeInstances)
        println("   ",i,") ", listeInstances[i])
    end
    choix = parse(Int64, choixListe(length(listeInstances)))

    # Parsing de l'instance
    f = open("instances/tsplib/"*librairie*listeInstances[choix])
    lignes = readlines(f)
    i = 1    
    while lignes[i] != "NODE_COORD_SECTION" 
        # On cherche le début des coordonées
        i += 1
    end
    nbPoints = length(lignes) - (i + 1) # Il y a i lignes au début + une ligne avec le EOF à la fin

    listePoints = Vector{Point}(undef, nbPoints)
    compteur = 1
    for i in (i+1):length(lignes)-1
        xClient, yClient = parse.(Float64, split(lignes[i])[2:3])
        pointClient = Point(xClient, yClient, string(compteur))
        listePoints[compteur] = pointClient
        compteur += 1
    end
    close(f)
    D = creationDistancier(nbPoints, listePoints)

    # Paramètres à renseigner manuellement
    println("\n========== Paramètres d'instance ==========")
    print("\n --> Vitesse du camion : ")
    vitesseCamion = parse(Float64, readline())
    print(" --> Vitesse du drone : " )
    vitesseDrone = parse(Float64, readline())
    println("\n========== Paramètres d'instance ==========")

    # Création de l'instance
    solution = Solution([], [], 0, 0) # Solution vide pour le moment
    instance = Instance(vitesseCamion, vitesseDrone, nbPoints, listePoints, D, solution, 0)
    return instance
end

