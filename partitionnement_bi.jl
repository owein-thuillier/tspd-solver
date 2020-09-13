function partitionnementBiObjectif(instance)
    V, A, P = AEPbiFiltrage(instance)
    graphiqueBis = plt.figure()
    plotPointsNonDomines(V, A, graphiqueBis)
    choix = choixBinaire("\n --> Souhaitez-vous calculer les points non-dominés supportés (o/n) ? ")
    if choix == "o"
        calculPointsSupportes(V, A, graphiqueBis)
    end
    solution = choixSolution(V, A)
    close(graphiqueBis)
    backtracking(instance, V, A, P, solution)
end

function backtracking(instance, V, A, P, solution)
    operationMinIJ = Array{Int64,2}(undef, length(instance.solution.ordreVisiteCamion), length(instance.solution.ordreVisiteCamion))
    for i in 1:length(instance.solution.ordreVisiteCamion)
        for j in 1:length(instance.solution.ordreVisiteCamion)
            operationMinIJ[i,j] = -100
        end
    end

    temp = []
    pred = P[end][solution]
    push!(temp, length(instance.solution.ordreVisiteCamion))
    push!(temp, pred[1])
    operationMinIJ[temp[end], temp[end-1]] = pred[3]
    while pred[1] != 1 
        pred = P[pred[1]][pred[2]]
        push!(temp, pred[1])
        operationMinIJ[temp[end], temp[end-1]] = pred[3]
    end
    temp = reverse(temp)

    ordreVisiteCamion = []
    operationsDrone = []
    push!(ordreVisiteCamion, 1)
    for i in 1:length(temp)-1
        operation = operationMinIJ[temp[i],temp[i+1]]
        if operation == -1 # Trajet direct
            noeudCombine = instance.solution.ordreVisiteCamion[temp[i+1]]
            push!(ordreVisiteCamion, noeudCombine)
        else # Opération drone
            noeudDrone = instance.solution.ordreVisiteCamion[operation]
            noeudDepart = instance.solution.ordreVisiteCamion[temp[i]]
            noeudFin = instance.solution.ordreVisiteCamion[temp[i+1]]
            push!(operationsDrone, [noeudDepart, noeudDrone, noeudFin])
            for l in temp[i]+1:temp[i+1]-1
                noeudActu = instance.solution.ordreVisiteCamion[l]
                if noeudActu != noeudDrone # Noeud camion
                    push!(ordreVisiteCamion, noeudActu)
                end
            end
            push!(ordreVisiteCamion, noeudFin)
        end
    end
    
    instance.solution.tempsParcours = V[end][solution]
    instance.solution.tempsAttente = A[end][solution]
    instance.solution.ordreVisiteCamion = ordreVisiteCamion
    instance.solution.operationsDrone = operationsDrone
    instance.codeResolution = 5
end

function choixSolution(V, A) # On choisit la solution à afficher (avec laquelle on effectue le backtracking)
    println("\n Liste des points non-dominés :")
    println(" ------------------------------")
    for i in 1:length(V[end])
        println(" --> $i) ($(V[end][i]),$(A[end][i]))")
        text(V[end][i]+1, A[end][i]+1, i) 
    end
    choix = choixListe(length(V[end]))
    return parse(Int64, choix)
end

function plotPointsNonDomines(V, A, graphiqueBis)
    ax = graphiqueBis.gca()
    ax.plot(V[end], A[end], marker="x", linestyle="", color="C0", label="Non-dominated points")
    title(L"#$Y_N =$ "*string(length(V[end])))
    grid(true)
    xlabel(L"$z_1$")
    ylabel(L"$z_2$")
    legend(loc="best")    
end

function calculPointsSupportes(V, A, graphiqueBis)
    ax = graphiqueBis.gca()
    listeDesPoints = [tuple(V[end][i],A[end][i]) for i in 1:length(V[end])]
    hull = convex_hull_graham_scan!(listeDesPoints) # On doit enlever les points non-supportés qui sont sur les bords de l'enveloppe convexe
 
    # On cherche les deux points extrêmes
    maxY = -Inf32
    maxIndice = -1
    minY = Inf32
    minIndice = -1
    for i in 1:length(hull) 
        if hull[i][2] < minY 
            minY = hull[i][2] 
            minIndice = i
        end
        if hull[i][2] > maxY 
            maxY = hull[i][2] 
            maxIndice = i
        end
    end

    # On cherche les points qui sont au-dessus (et donc à enlever)
    vecteurMinMax = [hull[minIndice][1] - hull[maxIndice][1], hull[minIndice][2] - hull[maxIndice][2]]
    hullNew = [hull[minIndice]]
    for i in 1:length(hull)
        if i != minIndice && i != maxIndice
            vecteur = [hull[i][1] - hull[maxIndice][1], hull[i][2] - hull[maxIndice][2]]
            produitVectoriel = (vecteurMinMax[1]*vecteur[2])-(vecteurMinMax[2]*vecteur[1])
            if produitVectoriel < 0 # ok : point supporté
                push!(hullNew, hull[i])
            end
        end
    end
    push!(hullNew, hull[maxIndice])
    hull = hullNew

    YSN = length(hull) 
    ax.plot(hull[1][1], hull[1][2], marker="x", color="red", linestyle="", label="Supported non-dominated points")
    for i in 1:length(hull)
        #println(cvh_graham[i])
        ax.plot(hull[i][1], hull[i][2], marker="x", color="red", linestyle="")
        if i != length(hull)
            ax.plot([hull[i][1],hull[i+1][1]], [hull[i][2],hull[i+1][2]], color="red", linestyle="--", linewidth=0.7) 
        end
    end

    YN = length(V[end]) 
    YSN = length(hull)
    YNN = YN - YSN
    title(L"#$Y_{N} =$ "*string(YN)*L"; #$Y_{SN} =$ "*string(YSN)*L"; #$Y_{NN} =$ "*string(YNN))
    legend(loc="best")
end


#################### Bi-objectif ####################

function tempsOperationBi(instance, i,j,k)
    solutionTSP = instance.solution.ordreVisiteCamion # Solution TSP : ordre de visite  du camion  
    # Debug
    #println(" Calcul du temps de l'opération : (i=$i, j=$j, k=$k)")
    #println(" Solution TSP : R_tsp = $solutionTSP")
    #print(" r_$i = $(solutionTSP[i]);")
    #print(" r_$j = $(solutionTSP[j]);")
    #if k != -1
    #    println(" r_$k = $(solutionTSP[k])")
    #end 
    # Calcul distance parcourue par le drone
    if k == -1 # Pas de noeud drone
        distanceDrone = 0
        ri = solutionTSP[i]
        rj = solutionTSP[j]
        distanceCamion = instance.D[ri,rj]
        tempsAttente = 0.0
    else
        ri = solutionTSP[i]
        rj = solutionTSP[j]
        rk = solutionTSP[k]
        distanceDrone = instance.D[ri,rk] + instance.D[rk,rj]
        distanceCamion = 0
        for l in i:(k-2)
            r1 = solutionTSP[l]
            r2 = solutionTSP[l+1]
            distanceCamion += instance.D[r1,r2]
        end
        rkAvant = solutionTSP[k-1]
        rkApres = solutionTSP[k+1]
        distanceCamion += instance.D[rkAvant,rkApres]
        for l in (k+1):(j-1)
            r1 = solutionTSP[l]
            r2 = solutionTSP[l+1]
            distanceCamion += instance.D[r1,r2]
        end
        tempsAttente = abs((distanceCamion/instance.vitesseCamion) - (distanceDrone/instance.vitesseDrone))
    end
    tempsParcours = max(distanceCamion/instance.vitesseCamion, distanceDrone/instance.vitesseDrone)
    return tempsParcours, tempsAttente
    #println(" Distance parcourue par le drone : $distanceDrone")
    #println(" Distance parcourue par le camion : $distanceCamion")
end

function calculMeilleuresOperationsBi(instance)
    solutionTSP = instance.solution.ordreVisiteCamion
    tempsMinIJ = Array{Vector{Float64},2}(undef, length(solutionTSP), length(solutionTSP))
    attenteIJ = Array{Vector{Float64},2}(undef, length(solutionTSP), length(solutionTSP))
    operationMinIJ = Array{Vector{Int64},2}(undef, length(solutionTSP), length(solutionTSP)) 
    for i in 1:length(solutionTSP)
        for j in 1:length(solutionTSP)
            tempsMinIJ[i,j] = Float64[]
            attenteIJ[i,j] = Float64[]
            operationMinIJ[i,j] = Int64[]
        end
    end
    for i in 1:length(solutionTSP)-1
        for j in i+1:length(solutionTSP)
            if j == i+1 # k = -1
                Tij, Aij = tempsOperationBi(instance, i, j, -1)
                operation = -1
                push!(tempsMinIJ[i, j], Tij)
                push!(attenteIJ[i, j], Aij)
                push!(operationMinIJ[i, j], operation)
            else
                # k > 0
                for k in (i+1):(j-1)
                    Tij, Aij = tempsOperationBi(instance, i, j, k)
                    operation = k
                    push!(tempsMinIJ[i, j], Tij)
                    push!(attenteIJ[i, j], Aij)
                    push!(operationMinIJ[i, j], operation)
                end 
            end
        end
    end
    return tempsMinIJ, operationMinIJ, attenteIJ
end

########## Filtrage pendant (iterative dominance filtering) ##########

function AEPbiFiltrage(instance)
    tempsMinIJ, operationMinIJ, attenteIJ = calculMeilleuresOperationsBi(instance)
    tempsMinIJ, attenteIJ, operationMinIJ = filtrageOperations(tempsMinIJ, operationMinIJ, attenteIJ, instance.solution.ordreVisiteCamion) # Filtrage par dominance des opérations T(i,j)

    V = []
    A = []
    P = []
    for i in 1:length(instance.solution.ordreVisiteCamion)
        push!(V, Float64[])
        push!(A, Float64[])
        push!(P, [])
    end
    
    push!(V[1], 0.0)
    push!(A[1], 0.0)
    push!(P[1], [-1,-1,-1]) # A changer
    for i in 2:length(V)
        #println(" $(i-1) : $(length(V[i-1]))")
        for k in 1:(i-1) 
            for y in 1:length(V[k])
                for z in 1:length(tempsMinIJ[k,i])
                    temps = V[k][y] + (tempsMinIJ[k,i])[z]
                    attente = A[k][y] + (attenteIJ[k,i])[z]
                    push!(V[i], temps)
                    push!(A[i], attente)
                    push!(P[i], [k,y, trunc(Int64, (operationMinIJ[k,i])[z]) ]) # On vient de V[k,m] et on a pris l'opération T(k,i,n)
                end
            end
        end
        Vtemp = []
        Atemp = []
        Ptemp = []
        for a in 1:length(V[i]) # On veut tester si le point i est dominé par un point j
            estDomine = false
            for b in 1:length(V[i])
                if b != a
                    if round(V[i][b], digits=5) == round(V[i][a], digits=5) && round(A[i][b], digits=5) == round(A[i][a], digits=5)
                        println(" Egalité V[i]") 
                    end
                    if round(V[i][b], digits=5) <= round(V[i][a], digits=5) && round(A[i][b], digits=5) <= round(A[i][a], digits=5)
                        estDomine = true
                        break
                    end
                end        
            end
            if estDomine == false
                push!(Vtemp, V[i][a])
                push!(Atemp, A[i][a])
                push!(Ptemp, P[i][a])
            end
        end 
        V[i] = Vtemp
        A[i] = Atemp
        P[i] = Ptemp
    end
    #println(" V = $V")
    #println(" A = $A")
    #println(" P = $P")
    return V, A, P
end

########## Filtrage par dominance des T(i,j) ##########

function filtrageOperations(tempsMinIJ, operationMinIJ, attenteIJ, solutionTSP)
    tempsMinIJBis = Array{Vector{Float64},2}(undef, length(solutionTSP), length(solutionTSP))  
    attenteIJBis = Array{Vector{Float64},2}(undef, length(solutionTSP), length(solutionTSP))  
    operationMinIJBis = Array{Vector{Float64},2}(undef, length(solutionTSP), length(solutionTSP)) 
    for i in 1:length(solutionTSP)
        for j in 1:length(solutionTSP)
            tempsMinIJBis[i,j] = Float64[]
            attenteIJBis[i,j] = Float64[]
            operationMinIJBis[i,j] = Int64[]
        end
    end

    for i in 1:length(solutionTSP)
        for j in i+1:length(solutionTSP)
            for l1 in 1:length(tempsMinIJ[i,j]) # Pour toutes les opérations dans T(i,j)
                estDomine = false # Test du point (i,j,l1)
                for l2 in 1:length(tempsMinIJ[i,j]) # Pour toutes les opérations dans T(i,j)
                    if l1 != l2
                        if round(tempsMinIJ[i,j][l2], digits=5) == round(tempsMinIJ[i,j][l1], digits=5) && round(attenteIJ[i,j][l2], digits=5) == round(attenteIJ[i,j][l1], digits=5) # Cas d'égalité
                            println(" Egalité operation")
                        end
                        if round(tempsMinIJ[i,j][l2], digits=5) <= round(tempsMinIJ[i,j][l1], digits=5) && round(attenteIJ[i,j][l2], digits=5) <= round(attenteIJ[i,j][l1], digits=5)
                            estDomine = true
                            break
                        end
                    end   
                end 
                if estDomine == false
                    push!(tempsMinIJBis[i,j], tempsMinIJ[i,j][l1])
                    push!(attenteIJBis[i,j], attenteIJ[i,j][l1])
                    push!(operationMinIJBis[i,j], operationMinIJ[i,j][l1])
                end   
            end          
        end
    end
    return tempsMinIJBis, attenteIJBis, operationMinIJBis
end

########## Graham ##########

function orient(p,q,r)
    pr_x = r[1] - p[1]
    pr_y = r[2] - p[2]
    rq_x = q[1] - r[1]
    rq_y = q[2] - r[2]
    sign(pr_x * rq_y - pr_y * rq_x)
end

function convex_hull_graham_scan!(points)
    @assert length(points) >= 3 "Too few points"
    sort!(points)  # in lexical order

    function build_convex_hull(points)
        n = length(points)
        hull = points[1:2]
        sizehint!(hull, n)

        for i in 3:n
            while true
                if orient(hull[end - 1], hull[end], points[i]) > 0
                    break
                else
                    pop!(hull)
                    if length(hull) < 2
                        break
                    end
                end
            end
            push!(hull, points[i])
        end

        hull
    end

    upper_hull = build_convex_hull(points)
    pop!(upper_hull)
    lower_hull = build_convex_hull(@view points[end:-1:1])
    pop!(lower_hull)

    [upper_hull; lower_hull]
end

function convex_hull_length(hull)
    hull2 = circshift(hull, -1)
    map((x, y) -> hypot((x .- y)...), hull2, hull) |> sum
end
