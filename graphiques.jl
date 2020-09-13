using PyPlot
using CSV
include("structures.jl")
include("utilitaires.jl")
include("parser.jl")
include("concorde.jl")
include("partitionnement_mono.jl")


function main()
    # Paramètres
    vitesseCamion = 1
    vitesseDrone = 3
    listeInstances = readdir("experimentations")
    nbInstances = length(listeInstances)

    # Première compilation
    instance = parserNousBis(listeInstances[1])
    instance.vitesseCamion = vitesseCamion
    instance.vitesseDrone = vitesseDrone
    concordeFast(instance)
    AEP(instance) 
    EP(instance) 

    # Expérimentation
    taillesInstance = trunc.(Int64, [1:120;])
    listeTempsTSP = Vector{Float64}(undef, 120)
    listeValeursTSP = Vector{Float64}(undef, 120)
    listeTempsAEP = Vector{Float64}(undef, 120)
    listeValeursAEP = Vector{Float64}(undef, 120)
    listeTempsEP = Vector{Float64}(undef, 120)
    listeValeursEP = Vector{Float64}(undef, 120)

    # Init
    for i in 1:length(taillesInstance)
        listeTempsTSP[i] = 0.0
        listeTempsAEP[i] = 0.0
        listeTempsEP[i] = 0.0
        listeValeursTSP[i] = 0.0
        listeValeursAEP[i] = 0.0
        listeValeursEP[i] = 0.0
    end

    # Début
    for i in 1:nbInstances
        instance = parserNousBis(listeInstances[i])
        instance.vitesseCamion = vitesseCamion
        instance.vitesseDrone = vitesseDrone
        println(" -> $i : $(instance.nbPoints)")
        tempsTSP = @elapsed concordeFast(instance)
        valTSP = instance.solution.tempsParcours
        listeTempsTSP[instance.nbPoints] += tempsTSP
        listeValeursTSP[instance.nbPoints] += valTSP
        tempsAEP = @elapsed AEP(instance) 
        valAEP = instance.solution.tempsParcours
        listeTempsAEP[instance.nbPoints] += tempsAEP
        listeValeursAEP[instance.nbPoints] += valAEP
        concordeFast(instance)
        tempsEP = @elapsed EP(instance) 
        valEP = instance.solution.tempsParcours
        listeTempsEP[instance.nbPoints] += tempsEP
        listeValeursEP[instance.nbPoints] += valEP
    end

    # Lissage
    listeTempsTSP = listeTempsTSP/20
    listeTempsAEP = listeTempsAEP/20
    listeTempsEP = listeTempsEP/20
    listeValeursTSP = listeValeursTSP/20
    listeValeursAEP = listeValeursAEP/20
    listeValeursEP = listeValeursEP/20

    graphique = plt.figure() # Sortie graphique unique
    ax = graphique.gca()
    #ax.title("CPUt for several instance sizes")
    xlabel(L"Instance size ($n$)")
    ylabel(L"Time ($s$)")
    xticks(taillesInstance[10:end])
    ax.plot(taillesInstance[10:end], listeTempsTSP[10:end], label="TSP")
    ax.plot(taillesInstance[10:end], listeTempsAEP[10:end], label="A1")
    ax.plot(taillesInstance[10:end], listeTempsEP[10:end], label="A2")
    ax.grid(true)
    ax.legend(loc="best")
    graphique2 = plt.figure() # Sortie graphique unique
    ax2 = graphique2.gca()
    #ax2.title(L"Value of $f_1$ for several instance sizes")
    xlabel(L"Instance size ($n$)")
    ylabel(L"$z_1$")
    xticks(taillesInstance[10:end])
    ax2.plot(taillesInstance[10:end], listeValeursTSP[10:end], label="TSP")
    ax2.plot(taillesInstance[10:end], listeValeursAEP[10:end], label="A1")
    ax2.plot(taillesInstance[10:end], listeValeursEP[10:end], label="A2")
    ax2.grid(true)
    ax2.legend(loc="best")
end

function expReverse()
    # Paramètres
    vitesseCamion = 1
    vitesseDrone = 3
    listeInstances = readdir("experimentations")
    nbInstances = length(listeInstances)


    taillesInstance = trunc.(Int64, [1:120;])
    A1gapZ1 = Vector{Float64}(undef, 120)
    A1gapZ2 = Vector{Float64}(undef, 120)
    A2gapZ1 = Vector{Float64}(undef, 120)
    A2gapZ2 = Vector{Float64}(undef, 120)

    # Début
    for i in 1:nbInstances
        instance = parserNousBis(listeInstances[i])
        instance.vitesseCamion = vitesseCamion
        instance.vitesseDrone = vitesseDrone

        println(" -> $i : $(instance.nbPoints)")
        tempsTSP = @elapsed concordeFast(instance)
        tempsParcoursTSP = instance.solution.tempsParcours
        ordreParcoursTSP = instance.solution.ordreVisiteCamion

        instance.solution = Solution(ordreParcoursTSP,[],tempsParcoursTSP,0)
        #println(" Parcours TSP : ", instance.solution.ordreVisiteCamion) 
        #println(" Temps parcours TSP : ", instance.solution.tempsParcours)
        tempsAEP = @elapsed AEP(instance) 
        #println(" AEP ")
        #println(" Parcours (z1) : ", instance.solution.tempsParcours)
        #println(" Parcours (z2) : ", instance.solution.tempsAttente)
        aepZ1 = instance.solution.tempsParcours
        aepZ2 = instance.solution.tempsAttente

        instance.solution = Solution(ordreParcoursTSP,[],tempsParcoursTSP,0)
        #println(" Parcours TSP : ", instance.solution.ordreVisiteCamion) 
        #println(" Temps parcours TSP : ", instance.solution.tempsParcours)
        tempsEP = @elapsed EP(instance) 
        #println(" EP ")
        #println(" Parcours (z1) : ", instance.solution.tempsParcours)
        #println(" Parcours (z2) : ", instance.solution.tempsAttente)
        epZ1 = instance.solution.tempsParcours
        epZ2 = instance.solution.tempsAttente

        reverse!(ordreParcoursTSP)
        #println(" REVERSE ")

        instance.solution = Solution(ordreParcoursTSP,[],tempsParcoursTSP,0)
        #println(" Parcours TSP : ", instance.solution.ordreVisiteCamion) 
        #println(" Temps parcours TSP : ", instance.solution.tempsParcours)
        tempsAEP = @elapsed AEP(instance) 
        #println(" AEP ")
        #println(" Parcours inverse (z1) : ", instance.solution.tempsParcours)
        #println(" Parcours inverse (z2) : ", instance.solution.tempsAttente)
        aepZ1reverse = instance.solution.tempsParcours
        aepZ2reverse = instance.solution.tempsAttente

        instance.solution = Solution(ordreParcoursTSP,[],tempsParcoursTSP,0)
        #println(" Parcours TSP : ", instance.solution.ordreVisiteCamion) 
        #println(" Temps parcours TSP : ", instance.solution.tempsParcours)
        tempsEP = @elapsed EP(instance) 
        #println(" EP ")
        #println(" Parcours inverse (z1) : ", instance.solution.tempsParcours)
        #println(" Parcours inverse (z2) : ", instance.solution.tempsAttente)
        epZ1reverse = instance.solution.tempsParcours
        epZ2reverse = instance.solution.tempsAttente

        #println(" Gap A1 z1 : ", ( 1 - ( min(aepZ1reverse, aepZ1)/max(aepZ1reverse, aepZ1) ) )*100, "%")
        #println(" Gap A1 z2 : ", (1-(min(aepZ2reverse, aepZ2)/max(aepZ2reverse, aepZ2)))*100, "%")
        #println(" Gap A2 z1 : ", (1-(min(epZ1reverse, epZ1)/max(epZ1reverse, epZ1)))*100, "%")
        #println(" Gap A2 z2 : ", (1-(min(epZ2reverse, epZ2)/max(epZ2reverse, epZ2)))*100, "%")
        A1gapZ1[instance.nbPoints] = (1-(min(aepZ1reverse, aepZ1)/max(aepZ1reverse, aepZ1)))*100
        A1gapZ2[instance.nbPoints] = (1-(min(aepZ2reverse, aepZ2)/max(aepZ2reverse, aepZ2)))*100
        A2gapZ1[instance.nbPoints] = (1-(min(epZ1reverse, epZ1)/max(epZ1reverse, epZ1)))*100
        A2gapZ2[instance.nbPoints] = (1-(min(epZ2reverse, epZ2)/max(epZ2reverse, epZ2)))*100
    end

    # Lissage
    A1gapZ1/20
    A1gapZ2/20
    A2gapZ1/20
    A2gapZ2/20
    
    meanA1z1 = 0.0
    meanA1z2 = 0.0
    meanA2z1 = 0.0
    meanA2z2 = 0.0
    for i in 10:120
        meanA1z1 += A1gapZ1[i]
        meanA1z2 += A1gapZ2[i]
        meanA2z1 += A2gapZ1[i]
        meanA2z2 += A2gapZ2[i]
    end
    meanA1z1 = meanA1z1/111
    meanA1z2 = meanA1z2/111
    meanA2z1 = meanA2z1/111
    meanA2z2 = meanA2z2/111
    
    
    graphique = plt.figure() # Sortie graphique unique
    ax = graphique.gca()
    # ax.title(M"Gap between $R_{TSP}$ and $R'_{TSP}$ (A1)")
    xlabel(L"Instance size ($n$)")
    ylabel(L"Gap ($\%$)")
    xticks(taillesInstance[10:end])
    ax.plot(taillesInstance[10:end], A1gapZ1[10:end], label=L"$z_1$", color="C1") # C1 : orange light
    ax.plot(taillesInstance[10:end], A1gapZ2[10:end], label=L"$z_2$", color="C0") # C0 : blue light
    ax.grid(true)
    axhline(y=meanA1z1, linestyle="--", label=L"mean $z_1$", color="C1")
    axhline(y=meanA1z2, linestyle="--", label=L"mean $z_2$", color="C0")
    ax.legend(loc="best")
    xticks([10,20,30,40,50,60,70,80,90,100,110,120])
    graphique2 = plt.figure() # Sortie graphique unique
    ax2 = graphique2.gca()
    #ax2.title(L"Value of $f_1$ for several instance sizes")
    xlabel(L"Instance size ($n$)")
    ylabel(L"Gap ($\%$)")
    xticks(taillesInstance[10:end])
    ax2.plot(taillesInstance[10:end], A2gapZ1[10:end], label=L"$z_1$", color="C1")
    ax2.plot(taillesInstance[10:end], A2gapZ2[10:end], label=L"$z_2$", color="C0")
    axhline(y=meanA2z1, linestyle="--", label=L"mean $z_1$", color="C1")
    axhline(y=meanA2z2, linestyle="--", label=L"mean $z_2$", color="C0")
    ax2.grid(true)
    ax2.legend(loc="best")
    xticks([10,20,30,40,50,60,70,80,90,100,110,120])
end

function etudeVitesse()
    # Paramètres
    listeInstances = readdir("experimentations")
    nbInstances = length(listeInstances)
    listeAlphas = [1:0.25:50;]
    listeZ1AEP = Vector{Float64}(undef, length(listeAlphas))
    listeZ1EP = Vector{Float64}(undef, length(listeAlphas))

    for j in 1:nbInstances
    println(" --> !!!! $j !!!!")
    vitesseCamion = 1
    vitesseDrone = 1
    instance = parserNousBis(listeInstances[j])
    instance.vitesseCamion = vitesseCamion
    instance.vitesseDrone = vitesseDrone
    concordeFast(instance)
    tempsParcoursTSP = instance.solution.tempsParcours
    ordreParcoursTSP = instance.solution.ordreVisiteCamion
    for i in 1:length(listeAlphas)
        println(" -> alpha : ", instance.vitesseDrone/instance.vitesseCamion)
        instance.solution = Solution(ordreParcoursTSP,[],tempsParcoursTSP,0)
        AEP(instance) 
        z1AEP = instance.solution.tempsParcours
        println(" -> z_1 AEP : $z1AEP")
        instance.solution = Solution(ordreParcoursTSP,[],tempsParcoursTSP,0)
        EP(instance) 
        z1EP = instance.solution.tempsParcours
        println(" -> z_1 EP : $z1EP")
        listeZ1AEP[i] += z1AEP
        listeZ1EP[i] += z1EP
        instance.vitesseCamion = vitesseCamion
        instance.vitesseDrone += 0.25
    end
    end

    listeZ1AEP = listeZ1AEP/nbInstances
    listeZ1EP = listeZ1EP/nbInstances

    
    println(listeAlphas)
    println(listeZ1AEP)
    println(listeZ1EP)

    graphique = plt.figure() # Sortie graphique unique
    ax = graphique.gca()
    # ax.title(M"Gap between $R_{TSP}$ and $R'_{TSP}$ (A1)")
    xlabel(L"$\alpha = \frac{speed_{drone}}{speed_{truck}}$")
    ylabel(L"z_1")
    ax.plot(listeAlphas, listeZ1AEP, label=L"A1", color="C1", linestyle="-") # C1 : orange light
    ax.plot(listeAlphas, listeZ1EP, label=L"A2", color="C0", linestyle="--") # C0 : blue light
    ax.grid(true)
    ax.legend(loc="best")
end

#### Expe Bi


function expBi()
    listeInstances = readdir("experimentations")
    nbInstances = length(listeInstances)
    cpt = 0
    cpt2 = 0
    for i in 1:1000
        print(" --> $i : ")
        instance = parserNousBis(listeInstances[i])
        instance.vitesseCamion = 1
        instance.vitesseDrone = 0.5
        concordeFast(instance)
        cptTemp, cpt2Temp = tempBi(instance)
        cpt += cptTemp
        cpt2 += cpt2Temp
    end
    println(" Same : $cpt")
    println(" Not same : $cpt2")
end

function tempBi(instance)
    nb1 = tempV1(instance)
    nb2 = tempV2(instance)
    if nb1 == nb2 
        println(" Same")
        cpt = 1
        cpt2 = 0
    else
        println(" Not same") 
        cpt = 0
        cpt2 = 1
    end
    return cpt, cpt2
end

function tempV1(instance)
    tempsMinIJ, operationMinIJ, attenteIJ = calculMeilleuresOperationsV1(instance)
    #display(tempsMinIJ)  
    #display(attenteIJ)  
    #display(operationMinIJ)  

    V = []
    A = []
    P = []
    for i in 1:length(instance.solution.ordreVisiteCamion)
        push!(V, [])
        push!(A, [])
        push!(P, [])
    end

    
    push!(V[1], 0.0)
    push!(A[1], 0.0)
    push!(P[1], -1) # A changer
    for i in 2:length(V)
        for k in 1:(i-1) 
            for m in 1:length(V[k])
                for n in 1:length(tempsMinIJ[k,i])
                    temps = V[k][m] + (tempsMinIJ[k,i])[n]
                    attente = A[k][m] + (attenteIJ[k,i])[n]
                    pred = k
                    push!(V[i], temps)
                    push!(A[i], attente)
                    push!(P[i], pred)
                end
            end
        end
    #plot(V[i], A[i], marker="x", linestyle="", color="C0")
    #grid(true)
    #title("2-objectifs")
    #xlabel("Temps de parcours total")
    #ylabel("Temps d'attente total")
    #clf()
    end

    #println(" V = $V")
    #println(" A = $A")
    #println(" P = $P")

    #plot(V[end], A[end], marker="x", linestyle="", color="C0")
    #grid(true)
    #title("2-objectifs")
    #xlabel("Temps de parcours total")
    #ylabel("Temps d'attente total")
    #println("\n Nombre de points (génération exhaustive) : ", length(V[end]))
    #clf()

    ND = []
    compteur = 0
    for i in 1:length(V[end]) # On veut tester si le point i est dominé par un point j
        estDomine = false
        for j in 1:length(V[end])
            if j != i
                if round(V[end][j], digits=5) <= round(V[end][i], digits=5) && round(A[end][j], digits=5) <= round(A[end][i], digits=5) # le point j est meilleur sur les 2 objectifs -> il domine le point i
                    estDomine = true
                    break
                end
            end        
        end
        if estDomine == false
            push!(ND, i)
            compteur += 1
            #println(" $(compteur)) z_1 = $(V[end][i]); z_2 = $(A[end][i])")
            #plot(V[end][i], A[end][i], marker="x", linestyle="", color="C1")
        end
    end 
    return length(ND)
end

function tempV2(instance)
    tempsMinIJ, operationMinIJ, attenteIJ = calculMeilleuresOperationsV2(instance)
    #display(tempsMinIJ)  
    #display(attenteIJ)  
    #display(operationMinIJ)  

    V = []
    A = []
    P = []
    for i in 1:length(instance.solution.ordreVisiteCamion)
        push!(V, [])
        push!(A, [])
        push!(P, [])
    end

    
    push!(V[1], 0.0)
    push!(A[1], 0.0)
    push!(P[1], -1) # A changer
    for i in 2:length(V)
        for k in 1:(i-1) 
            for m in 1:length(V[k])
                for n in 1:length(tempsMinIJ[k,i])
                    temps = V[k][m] + (tempsMinIJ[k,i])[n]
                    attente = A[k][m] + (attenteIJ[k,i])[n]
                    pred = k
                    push!(V[i], temps)
                    push!(A[i], attente)
                    push!(P[i], pred)
                end
            end
        end
    #plot(V[i], A[i], marker="x", linestyle="", color="C0")

    end

    ND = []
    compteur = 0
    for i in 1:length(V[end]) # On veut tester si le point i est dominé par un point j
        estDomine = false
        for j in 1:length(V[end])
            if j != i
                if round(V[end][j], digits=5) <= round(V[end][i], digits=5) && round(A[end][j], digits=5) <= round(A[end][i], digits=5) # le point j est meilleur sur les 2 objectifs -> il domine le point i
                    estDomine = true
                    break
                end
            end        
        end
        if estDomine == false
            push!(ND, i)
            compteur += 1
            #println(" $(compteur)) z_1 = $(V[end][i]); z_2 = $(A[end][i])")
            #plot(V[end][i], A[end][i], marker="x", linestyle="", color="C1")
        end
    end 
    return length(ND)
end


expReverse()


