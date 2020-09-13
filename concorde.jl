# Interface Concorde / Julia

function versTSPLIB(instance)
    sortie = open("temp/instance_TSPLIB", "w")
    write(sortie, "NAME : none")
    write(sortie, "\nCOMMENT : none")
    write(sortie, "\nTYPE : TSP")
    write(sortie, "\nDIMENSION : "*string(instance.nbPoints))
    write(sortie, "\nEDGE_WEIGHT_TYPE : EUC_2D")
    write(sortie, "\nNODE_COORD_SECTION")
    for i in 1:instance.nbPoints
        # On multiplie par 1000 car Concorde ne gère pas les flottants, cela évite donc de se retrouver avec des erreurs liées aux arrondies 
        # Les distances sur certaines instances peuvent en effet être sensiblement proches 
        write(sortie, "\n"*string(i)*" "*string(instance.listePoints[i].x*1000)*" "*string(instance.listePoints[i].y*1000))
    end
    write(sortie, "\nEOF")
    close(sortie);
end

function lectureSolutionLINKERN()
    # On lit la solution dans le fichier de sortie après exécution programme linkern
    f = open("temp/res") 
    lignes = readlines(f)
    ordreVisite = []
    push!(ordreVisite, 1)
    for i in 2:size(lignes,1)
       push!(ordreVisite, parse.(Int64, split(lignes[i])[2]) + 1)
    end
    close(f)
    return ordreVisite
end

function lectureSolutionCONCORDE()
    # On lit la solution dans le fichier de sortie après exécution programme concorde 
    f = open("temp/res")
    lignes = readlines(f)
    ordreVisite = []
    l = 2
    n = 1
    for i in 1:parse.(Int64, lignes[1])
       push!(ordreVisite, parse.(Int64, split(lignes[l])[n]) + 1)
       if mod(i,10) == 0 # 10 noeuds par ligne
           l += 1
           n = 1
       else
           n += 1
       end 
    end
    push!(ordreVisite, 1)
    close(f)
    return ordreVisite
end

function resolutionConcorde(instance)
    asciiArtAvion()
    versTSPLIB(instance) # On convertit l'instance courante vers le format TSPLIB (compatible Concorde)

    println("\n Choix du type de résolution (TSP) :")
    println(" -----------------------------------")
    println("    --> 1) Exacte")
    println("    --> 2) Approchée : Lin-Kernighan (à personnaliser)")
    println("    --> 3) Approchée : Lin-Kernighan (défaut)")
    choix = choixListe(3) 
    if choix == "1"
         run(pipeline(`./concorde/concorde -o temp/res temp/instance_TSPLIB`, stdout=devnull, stderr=devnull))
         ordreVisite = lectureSolutionCONCORDE()
         instance.codeResolution = 1
    elseif choix == "2"
         println("\n Construction initiale : ")
         println(" -----------------------")
         println("    --> 1) Aléatoire")
         println("    --> 2) Nearest-Neighbor")
         println("    --> 3) Glouton") 
         println("    --> 4) Boruvka")
         println("    --> 5) Quick-Boruvka")
         choix = choixListe(5)  
         constructionInitiale = string((parse(Int64, choix)-1))
         # Note : on repasse le choix en int pour y soustraire une unité et correspondre aux choix proposés par le programme linkern
         # 0 : Aléatoire, 1 : Nearest-Neighbor, 2 : Glouton, 3 : Boruvka, 4 : Quick-Boruvka
         # On repasse ensuite en string pour personnaliser la commande ci-dessous

         println("\n Choix du kick : ")
         println(" ---------------")
         println("    --> 1) Aléatoire")
         println("    --> 2) Géométrique")
         println("    --> 3) Close") 
         println("    --> 4) Marche Aléatoire")
         choix = choixListe(4)  
         kick = string((parse(Int64, choix)-1))

         print("\n Temps limite de résolution (secondes) : ")
         tempsLimite = readline()
         tempsLimite = parse(Int64, tempsLimite)

         run(pipeline(`./concorde/linkern -I $constructionInitiale -K $kick -t $tempsLimite -o temp/res temp/instance_TSPLIB`, stdout=devnull, stderr=devnull)) # On sauvegarde le résultat de la résolution dans le fichier temporaire res et on ne conserve pas l'affichage textuelle
         ordreVisite = lectureSolutionLINKERN()
         instance.codeResolution = 2
    elseif choix == "3"
        # Ici on exécute Lin-Kernighan avec les choix par défaut
        # Quick-boruvka + Random_walk kicks
        # Nombre de kicks : nombre de noeuds
        run(pipeline(`./concorde/linkern -o temp/res temp/instance_TSPLIB`, stdout=devnull, stderr=devnull))
        ordreVisite = lectureSolutionLINKERN()
        instance.codeResolution = 2
    end
    run(`./clean.sh`) # On supprime les fichiers résiduels
    # Note : on ne peut pas utiliser le pattern * (propre au shell) avec la fonction run(), il semblerait que cela va être implémenté dans les prochaines versions de Julia (vu sur discourse.julialang.org : "using * as a wildcard in backtick commands"). 
    # Pour cette raison, on passe par un script Shell annexe pour supprimer les fichiers temporaires
    solution = Solution(ordreVisite, [], coutTour(ordreVisite, instance), 0)
    instance.solution = solution
end

function asciiArtAvion()
    println("")
    println(" _____         ______  ")
    println("| : \\         |    \\   ")
    println("| :  `\\______|______\\_______ ")
    println(" \\'______    Concorde  \\_____\\_____ ")
    println("   \\____/-)_,---------,_____________>-- ")
    println("             \\       / ")
    println("              |     / ")
    println("              |____/__  ")
    println("")
end


########## Fonctions rapides (sans affichage ni lecture utilisateur) ##########


function concordeFast(instance) # 0 verbosité
    versTSPLIB(instance)
    run(pipeline(`./concorde/concorde -o temp/res temp/instance_TSPLIB`, stdout=devnull, stderr=devnull))
    ordreVisite = lectureSolutionCONCORDE()
    instance.codeResolution = 1
    run(`./clean.sh`) # On supprime les fichiers résiduels
    solution = Solution(ordreVisite, [], coutTour(ordreVisite, instance), 0)
    instance.solution = solution
end

function lkhFast(instance) # 0 verbosité
    versTSPLIB(instance)
    run(pipeline(`./concorde/linkern -o temp/res temp/instance_TSPLIB`, stdout=devnull, stderr=devnull))
    ordreVisite = lectureSolutionLINKERN()
    instance.codeResolution = 2
    run(pipeline(`./clean.sh`, stderr=devnull)) # On supprime les fichiers résiduels
    solution = Solution(ordreVisite, [], coutTour(ordreVisite, instance), 0)
    instance.solution = solution
end




