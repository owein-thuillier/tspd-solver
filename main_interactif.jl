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
        instance = choixInstance()
        caracteristiquesInstance(instance)
        graphique = initGraphique(instance)

        # Mode interactif
        mode_interactif(instance, graphique)

        # Continuer
        continuer = choixBinaire("\n --> Souhaitez-vous continuer (o/n) ? ")
     end
     close()
end

function mode_interactif(instance, graphique) # Possible de replacer les points + changer les vitesses
    manuel()
    cid1 = saveInstance(instance, graphique) 
    cid2, cid3 = replacementPoints(instance, graphique)
    cid4 = influenceVitesse(instance, graphique)
    cid5 = resolution(instance, graphique)
    readline()
    graphique.canvas.mpl_disconnect(cid1)
    graphique.canvas.mpl_disconnect(cid2)
    graphique.canvas.mpl_disconnect(cid3)
    graphique.canvas.mpl_disconnect(cid4)
end

function manuel()
    println("\n========== Mode interactif - Manuel ==========")
    println("\n Aide :")
    println(" ------")
    println("\n h : Afficher le manuel à nouveau")
    println("\n Résolutions :")
    println(" -------------") 
    println("\n e : Affichage solution mode console")
    println(" r : Reset")
    println(" t : TSP via CONCORDE")
    println(" y : TSP via LKH")
    println(" u : TSP-D via A1 (AEP)")
    println(" i : TSP-D via A2 (EP)")
    println("\n Enregistrer l'instance (notre format) :")
    println(" ---------------------------------------") 
    println("\n b : Enregistre l'instance dans le dossier \"instances/nous/bibliotheque_autres/\"")
    println("\n Déplacer un point :")
    println(" -------------------") 
    println("\n Vous pouvez déplacer un point en cliquant sur celui-ci (une fois), \n puis en cliquant à nouveau (une fois) sur le point \n après l'avoir déplacé à l'endroit souhaité.")
    println("\n\n Modifier les vitesses :")
    println(" -----------------------") 
    println("\n /!\\ Cliquez sur la fenêtre graphique au préalable /!\\")
    println("\n w : vitesse camion -0.5")
    println(" x : vitesse camion +0.5")
    println(" c : vitesse drone -0.5")
    println(" v : vitesse drone +0.5")
    println("\n /!\\ Pour continuer, appuyer sur la touche \"Entrée\" \n en cliquant au préalable sur la console /!\\")
    println("\n========== Mode interactif ==========\n")
end


########## Interactions ##########


##### Replacement des points #####

function replacementPoints(instance, graphique)
    x0 = 0.0
    y0 = 0.0
    select = false # indique si un point est selectionné
    indicePoint = -1
    point = [x0, y0, select, indicePoint] 
    cid1 = graphique.canvas.mpl_connect("pick_event", event -> onpick(event, point, instance, graphique))
    cid2 = graphique.canvas.mpl_connect("motion_notify_event", event -> motion(event, point, instance, graphique))
    return cid1, cid2
end

function onpick(event, point, instance, graphique)
    if point[3] == false # Pas de point selectionné
        thisline = event.artist
        xdata = thisline.get_xdata()
        ydata = thisline.get_ydata()
        ind = event.ind[1] + 1 # Car les indices commencent à 0 en python
        #println(ind)
        #println("$(xdata[ind])")
        #println("$(ydata[ind])")
        indicePoint = -1
        for i in 1:length(instance.listePoints)
            if instance.listePoints[i].x == xdata[ind][1] && instance.listePoints[i].y == ydata[ind][1] # On a trouvé le point correspondant
                #println("Point selectionné : ", instance.listePoints[i]) 
                indicePoint = i
            end 
        end
        point[1], point[2], point[3], point[4] = xdata[ind][1], ydata[ind][1], true, indicePoint
    elseif point[3] == true
        point[1], point[2], point[3], point[4] = 0.0, 0.0, false, -1 # On reset, le point a été replacé 
        if instance.codeResolution != 0 # Si il y a eu une résolution au préalable
            if  instance.codeResolution == 1 # Résolu avec TSP précédemment
                concordeFast(instance)
            elseif instance.codeResolution == 2 # Résolu avec Lkh  ""
                lkhFast(instance)
            elseif instance.codeResolution == 3 # AEP
                concordeFast(instance)
                AEP(instance)
            elseif instance.codeResolution == 4 # EP
                concordeFast(instance)
                EP(instance)
            end
        end
        majGraphique(instance, graphique)
    end
end

function motion(event, point, instance, graphique)
    if point[3] == true # Un point a été sélectionné
        indice = trunc(Int64, point[4])
        instance.listePoints[indice].x = event.xdata[1]
        instance.listePoints[indice].y = event.ydata[1]
        D = creationDistancier(instance.nbPoints, instance.listePoints) # Fastidieux (pas efficace) --> on devrait maj seulement les pts concernés
        instance.D = D
        majGraphique(instance, graphique)
    end
end

##### Influence vitesse #####

function on_key(event, instance, graphique)
    maj = false # Si mise à jour nécessaire : maj = true
    if event.key == "w" # vitesse camion -
        if instance.vitesseCamion != 0.5
            instance.vitesseCamion -= 0.5
            maj = true
        end
    elseif event.key == "x" # vitesse camion +
        instance.vitesseCamion += 0.5
        maj = true
    elseif event.key == "c" # vitesse drone -
        if instance.vitesseDrone != 0.5
            instance.vitesseDrone -= 0.5
            maj = true
        end
    elseif event.key == "v" # vitesse drone +
        instance.vitesseDrone += 0.5
        maj = true
    end
    
    if maj == true
        # Augmenter la vitesse change juste la solution de AEP/EP
        if instance.codeResolution == 3
            concordeFast(instance)
            AEP(instance)
        elseif instance.codeResolution == 4
            concordeFast(instance)
            EP(instance)
        end
        majGraphique(instance, graphique)
    end
end

function influenceVitesse(instance, graphique)
    cid = graphique.canvas.mpl_connect("key_press_event", event -> on_key(event, instance, graphique))
    return cid
end

##### Résolutions diverses + Manuel #####

function on_key_2(event, instance, graphique)
    maj = false # Si mise à jour nécessaire : maj = true
    if event.key == "t"
        concordeFast(instance)
        majGraphique(instance, graphique)
    elseif event.key == "y"
        lkhFast(instance)
        majGraphique(instance, graphique)
    elseif event.key == "u"
        if instance.codeResolution == 1 || instance.codeResolution == 2
            AEP(instance)
            majGraphique(instance, graphique)
        end
    elseif event.key == "i"
        if instance.codeResolution == 1 || instance.codeResolution == 2
            EP(instance)
            majGraphique(instance, graphique)
        end
    elseif event.key == "r" # Reset
        instance.codeResolution = 0
        instance.solution = Solution([], [], 0, 0)
        majGraphique(instance, graphique)
    elseif event.key == "m"
        manuel()
    elseif event.key == "e"
        if instance.codeResolution != 0
            affichageSolution(instance)
        end
    elseif event.key == "h"
        manuel()
    end
end

function resolution(instance, graphique)
    cid = graphique.canvas.mpl_connect("key_press_event", event -> on_key_2(event, instance, graphique))
    return cid
end

##### Sauvegarde instance #####

function on_keybis(event, instance, graphique)
    if event.key == "b"
        nom = string(Dates.now()) # Date + heure précise en guise de nom unique : année-mois-jourTheures-minutes-secondes
        enregistrerInstance(instance, nom)
        println(" Instance enregistrée sous le nom : $nom")
    end
end

function saveInstance(instance, graphique)
    cid = graphique.canvas.mpl_connect("key_press_event", event -> on_keybis(event, instance, graphique))
    return cid
end


main()
