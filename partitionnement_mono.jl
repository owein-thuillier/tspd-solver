function partitionnementMonoObjectif(instance)
    println("\n Choix du partitionnement exact :")
    println(" --------------------------------")
    println("  1) Agatz Exact Partitionning (AEP = A1)")
    println("  2) Poikonen Exact Partitionning (EP = A2)")
    choix = choixListe(2)
    if choix == "1"
        AEP(instance)
    elseif choix == "2"
        EP(instance)
    end
end

function tempsOperation(instance, i,j,k)
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

function calculMeilleuresOperations(instance)
    solutionTSP = instance.solution.ordreVisiteCamion
    # Permet de calculer la meilleure opération pour aller de ri à rj pour toutes les sous-séquences (i,...,j) de solutionTSP
    tempsMinIJ = Array{Float64,2}(undef, length(solutionTSP), length(solutionTSP)) # Temps de la meilleure opération pour aller de i à j
    attenteIJ = Array{Float64,2}(undef, length(solutionTSP), length(solutionTSP)) # Attente liée à la meilleure opération pour aller de i à j
    operationMinIJ = Array{Int64,2}(undef, length(solutionTSP), length(solutionTSP)) # Noeud drone correspondant à la meilleure opération pour aller de i à j (-1 si pas de noeud drone)
    for i in 1:length(solutionTSP)
        for j in 1:length(solutionTSP)
            tempsMinIJ[i,j] = -Inf32
            operationMinIJ[i,j] = -100
        end
    end
    for i in 1:length(solutionTSP)-1
        for j in i+1:length(solutionTSP)
            if j == i+1 # k = -1
                tempsMinIJ[i, j], attenteIJ[i, j] = tempsOperation(instance, i, j, -1)
                operationMinIJ[i, j] = -1
            else
                minTij = Inf32
                attente = Inf32
                operation = -100
                # k > 0
                for k in (i+1):(j-1)
                    Tij, Aij = tempsOperation(instance, i, j, k)
                    if Tij < minTij
                        minTij = Tij
                        attente = Aij
                        operation = k
                    end
                end 
                tempsMinIJ[i, j] = minTij
                attenteIJ[i, j] = attente
                operationMinIJ[i, j] = operation
            end
        end
    end
    return tempsMinIJ, operationMinIJ, attenteIJ
end

function AEP(instance)
    tempsMinIJ, operationMinIJ, attenteIJ = calculMeilleuresOperations(instance)
    V = Vector{Float64}(undef, length(instance.solution.ordreVisiteCamion))
    A = Vector{Float64}(undef, length(instance.solution.ordreVisiteCamion))
    P = Vector{Int64}(undef, length(instance.solution.ordreVisiteCamion))
    V[1] = 0
    A[1] = 0
    P[1] = -1

    for i in 2:length(V)
        minTemps = Inf32
        attenteAssociee = Inf32
        pred = -1
        for k in 1:(i-1)
            temps = V[k] + tempsMinIJ[k,i]
            attente = A[k] + attenteIJ[k,i]
            if temps < minTemps
                minTemps = temps
                attenteAssociee = attente
                pred = k
            end
        end
        V[i] = minTemps
        A[i] = attenteAssociee
        P[i] = pred
    end
    #println(" V = $V")
    #println(" A = $A")
    #println(" P = $P")

    temp = []
    pred = P[end]
    push!(temp, length(instance.solution.ordreVisiteCamion))
    push!(temp, pred)
    while pred != 1 
        pred = P[pred]
        push!(temp, pred)
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
    
    instance.solution.tempsParcours = V[end]
    instance.solution.tempsAttente = A[end]
    instance.solution.ordreVisiteCamion = ordreVisiteCamion
    instance.solution.operationsDrone = operationsDrone
    instance.codeResolution = 3
end


#################### Poikonen (EP) ####################

function tempsOperationEP(instance, i,j,k)
    solutionTSP = instance.solution.ordreVisiteCamion # Solution TSP : ordre de visite  du camion  
    # Calcul distance parcourue par le drone
    bestY = -100 # Pour le cas k == -3
    bestZ = -100
    if k == -1 # Pas de noeud drone
        ri = solutionTSP[i]
        rj = solutionTSP[j]
        distanceCamion = instance.D[ri,rj]
        tempsParcours = distanceCamion/instance.vitesseCamion
        tempsAttente = 0.0
    elseif k == -2
        ri = solutionTSP[i]
        rj = solutionTSP[j]
        # Le camion va de ri à rj
        distanceCamion = instance.D[ri,rj]
        distanceDrone = 0
        for l in (i+1):(j-1)
            rl = solutionTSP[l]
            distanceDrone += 2 * instance.D[ri,rl]
        end
        tempsParcours = (distanceCamion/instance.vitesseCamion) + (distanceDrone/instance.vitesseDrone)
        tempsAttente = (distanceDrone/instance.vitesseDrone) # Le camion doit attendre que le drone termine la livraison
    elseif k == -3
        minTempsParcours = Inf32 
        minTempsAttente = Inf32
        tempsP = 0.0
        tempsA = 0.0
        for z in (i+1):(j-2)
            for y in (z+1):(j-1)
                tempsP, tempsA = T(instance,i,j,z,y)
                if tempsP < minTempsParcours
                    minTempsParcours = tempsP
                    minTempsAttente = tempsA
                    bestY = y
                    bestZ = z
                end
            end
        end
        tempsParcours = tempsP
        tempsAttente = tempsA
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
        tempsParcours = max(distanceCamion/instance.vitesseCamion, distanceDrone/instance.vitesseDrone)
        tempsAttente = abs((distanceCamion/instance.vitesseCamion) - (distanceDrone/instance.vitesseDrone))
    end
    return tempsParcours, tempsAttente, bestY, bestZ
    #println(" Distance parcourue par le drone : $distanceDrone")
    #println(" Distance parcourue par le camion : $distanceCamion")
end

function T(instance, i,j,z,y) # k = -3
    solutionTSP = instance.solution.ordreVisiteCamion # Solution TSP : ordre de visite  du camion  
    ri = solutionTSP[i]
    rj = solutionTSP[j] 
    # Allers-retours drone
    distanceDroneEtape1 = 0
    for l in (i+1):z
        rl = solutionTSP[l]
        distanceDroneEtape1 += 2 * instance.D[ri,rl]
    end   
    # Le reste
    ry = solutionTSP[y]
    distanceDroneEtape2 = instance.D[ri,ry] + instance.D[ry,rj]
    distanceCamion = 0.0
    if y == z+1 && j != y+1 ## Cas w1 vide (i -> i+1 -> ... -> z -> y -> w_2_1 -> ... -> j)
        rw21 = solutionTSP[y+1]
        distanceCamion = instance.D[ri,rw21]
        for l in (y+1):(j-1)
            rw2_l1 = solutionTSP[l] 
            rw2_l2 = solutionTSP[l+1] 
            distanceCamion += instance.D[rw2_l1,rw2_l2] 
        end
    elseif y != z+1 && j == y+1 ## Cas w2 vide (i -> i+1 -> ... -> z -> w_1_1 > ... -> y -> j)
        rw11 = solutionTSP[z+1]
        distanceCamion = instance.D[ri,rw11]
        for l in (z+1):(y-2) # On ne livre pas y
            rw1_l1 = solutionTSP[l] 
            rw1_l2 = solutionTSP[l+1] 
            distanceCamion += instance.D[rw1_l1,rw1_l2] 
        end 
        rw1 = solutionTSP[y-1] 
        distanceCamion += instance.D[rw1,rj]  
    elseif y == z+1 && j == y+1 ## Cas w1 et w2 vides (i -> i+1 -> ... -> z -> y -> j)
        distanceCamion = instance.D[ri,rj]    
    elseif y != z+1 && j != y+1 ## Cas w1 et w2 avec au moins 1 noeud (i -> i+1 -> ... -> z -> w_1_1 -> ... -> y -> w_2_1 -> ... -> j)
        rw11 = solutionTSP[z+1]
        distanceCamion = instance.D[ri,rw11]
        for l in (z+1):(y-2) # On ne livre pas y
            rw1_l1 = solutionTSP[l] 
            rw1_l2 = solutionTSP[l+1] 
            distanceCamion += instance.D[rw1_l1,rw1_l2] 
        end 
        rw1 = solutionTSP[y-1] 
        rw21 = solutionTSP[y+1]
        distanceCamion = instance.D[rw1,rw21]
        for l in (y+1):(j-1)
            rw2_l1 = solutionTSP[l] 
            rw2_l2 = solutionTSP[l+1] 
            distanceCamion += instance.D[rw2_l1,rw2_l2] 
        end
    end
    tempsParcours = distanceDroneEtape1/instance.vitesseDrone + max(distanceDroneEtape2/instance.vitesseDrone, distanceCamion/instance.vitesseCamion)
    tempsAttente = (distanceDroneEtape1/instance.vitesseDrone) + abs(distanceDroneEtape2/instance.vitesseDrone - distanceCamion/instance.vitesseCamion)
    return tempsParcours, tempsAttente
end

function calculMeilleuresOperationsEP(instance)
    solutionTSP = instance.solution.ordreVisiteCamion
    # Permet de calculer la meilleure opération pour aller de ri à rj pour toutes les sous-séquences (i,...,j) de solutionTSP
    tempsMinIJ = Array{Float64,2}(undef, length(solutionTSP), length(solutionTSP)) # Temps de la meilleure opération pour aller de i à j
    attenteIJ = Array{Float64,2}(undef, length(solutionTSP), length(solutionTSP)) # Attente liée à la meilleure opération pour aller de i à j
    operationMinIJ = Array{Vector{Int64},2}(undef, length(solutionTSP), length(solutionTSP)) # Noeud drone correspondant à la meilleure opération pour aller de i à j (-1 si pas de noeud drone)
    bestY = -100 
    bestZ = -100
    for i in 1:length(solutionTSP)
        for j in 1:length(solutionTSP)
            tempsMinIJ[i,j] = -Inf32
            operationMinIJ[i,j] = [-100]
        end
    end
    for i in 1:length(solutionTSP)-1
        for j in i+1:length(solutionTSP)
            if j == i+1 # k = -1
                tempsMinIJ[i, j], attenteIJ[i, j] = tempsOperationEP(instance, i, j, -1)
                operationMinIJ[i, j] = [-1]
            else
                minTij = Inf32
                attente = Inf32
                operation = -100
                # k > 0
                for k in (i+1):(j-1)
                    Tij, Aij = tempsOperationEP(instance, i, j, k)
                    if Tij < minTij
                        minTij = Tij
                        attente = Aij
                        operation = k
                    end
                end 
                # k = -2
                Tij, Aij = tempsOperationEP(instance, i, j, -2)
                if Tij < minTij
                    minTij = Tij
                    attente = Aij
                    operation = -2
                end
                # k = -3
                if j >= i+3 # Minimum pour placer z et y
                    Tij, Aij, bestY, bestZ = tempsOperationEP(instance, i, j, -3)
                    if Tij < minTij
                        minTij = Tij
                        attente = Aij
                        operation = -3
                    end
                end
                tempsMinIJ[i, j] = minTij
                attenteIJ[i, j] = attente
                operationMinIJ[i, j] = [operation, bestY, bestZ] # Pour gérer le cas k = -3
            end
        end
    end
    return tempsMinIJ, operationMinIJ, attenteIJ
end

function EP(instance)
    tempsMinIJ, operationMinIJ, attenteIJ = calculMeilleuresOperationsEP(instance)
    V = Vector{Float64}(undef, length(instance.solution.ordreVisiteCamion))
    A = Vector{Float64}(undef, length(instance.solution.ordreVisiteCamion))
    P = Vector{Int64}(undef, length(instance.solution.ordreVisiteCamion))
    V[1] = 0
    A[1] = 0
    P[1] = -1
    for i in 2:length(V)
        minTemps = Inf32
        attenteAssociee = Inf32
        pred = -1
        for k in 1:(i-1)
            temps = V[k] + tempsMinIJ[k,i]
            attente = A[k] + attenteIJ[k,i]
            if temps < minTemps
                minTemps = temps
                attenteAssociee = attente
                pred = k
            end
        end
        V[i] = minTemps
        A[i] = attenteAssociee
        P[i] = pred
    end
    #println(" V = $V")
    #println(" A = $A")
    #println(" P = $P")

    temp = []
    pred = P[end]
    push!(temp, length(instance.solution.ordreVisiteCamion))
    push!(temp, pred)
    while pred != 1 
        pred = P[pred]
        push!(temp, pred)
    end
    temp = reverse(temp)

    ordreVisiteCamion = []
    operationsDrone = []
    push!(ordreVisiteCamion, 1)
    for i in 1:length(temp)-1
        operation = operationMinIJ[temp[i],temp[i+1]][1] # (operation, bestY, bestZ)
        if operation == -1 # Trajet direct
            noeudCombine = instance.solution.ordreVisiteCamion[temp[i+1]]
            push!(ordreVisiteCamion, noeudCombine)
        elseif operation == -2
            noeudDepart = instance.solution.ordreVisiteCamion[temp[i]]
            noeudFin = instance.solution.ordreVisiteCamion[temp[i+1]]
            push!(ordreVisiteCamion, noeudFin)
            for l in temp[i]+1:temp[i+1]-1
                noeudDrone = instance.solution.ordreVisiteCamion[l]
                push!(operationsDrone, [noeudDepart, noeudDrone, noeudDepart]) # [i,k,j]
            end
        elseif operation == -3
            ri = instance.solution.ordreVisiteCamion[temp[i]]
            rj = instance.solution.ordreVisiteCamion[temp[i+1]]
            ry = instance.solution.ordreVisiteCamion[operationMinIJ[temp[i],temp[i+1]][2]]
            rz = instance.solution.ordreVisiteCamion[operationMinIJ[temp[i],temp[i+1]][3]]
            #println(" Ordre visite camion TSP : ", instance.solution.ordreVisiteCamion)
            #println(" ri = $ri")
            #println(" rj = $rj")
            #println(" ry = $ry")
            #println(" rz = $rz")
            #i = temp[i]
            #j = temp[i+1]
            y = operationMinIJ[temp[i],temp[i+1]][2]
            z = operationMinIJ[temp[i],temp[i+1]][3]
            # Etape 1 : Allers-retours du drone
            for l in (temp[i]+1):z
                noeudDrone = instance.solution.ordreVisiteCamion[l]
                push!(operationsDrone, [ri, noeudDrone, ri]) # [i,k,j]
            end
            # Etape 2
            if y == z+1 && temp[i+1] == y+1 ## Cas w1 et w2 vides (i -> i+1 -> ... -> z -> y -> j)
                #println(" --> Cas w1 et w2 vides")
                push!(ordreVisiteCamion, rj) # Le camion va en j directement  
                push!(operationsDrone, [ri, ry, rj]) # Le drone livre y puis rejoint le camion en j    
            elseif y != z+1 && temp[i+1] != y+1 ## Cas w1 et w2 avec au moins 1 noeud (i -> i+1 -> ... -> z -> w_1_1 -> ... -> y -> w_2_1 -> ... -> j) 
                push!(operationsDrone, [ri, ry, rj]) # Le drone livre y puis rejoint le camion en j    
                for l in (z+1):(y-1) # On ne livre pas y
                    rw1_l1 = instance.solution.ordreVisiteCamion[l]
                    push!(ordreVisiteCamion, rw1_l1) # Le camion va en j directement   
                end
                for l in (y+1):temp[i+1]
                    rw2_l1 = instance.solution.ordreVisiteCamion[l]
                    push!(ordreVisiteCamion, rw2_l1)   
                end
                #println(" --> Cas w1 et w2 avec au moins 1 noeud")
            elseif y == z+1 && temp[i+1] != y+1 ## Cas w1 vide (i -> i+1 -> ... -> z -> y -> w_2_1 -> ... -> j)
                #println(" --> Cas w1 vide")
                push!(operationsDrone, [ri, ry, rj]) # Le drone livre y puis rejoint le camion en j    
                for l in (y+1):temp[i+1]
                    rw2_l1 = instance.solution.ordreVisiteCamion[l]
                    push!(ordreVisiteCamion, rw2_l1)   
                end
            elseif y != z+1 && temp[i+1] == y+1 ## Cas w2 vide (i -> i+1 -> ... -> z -> w_1_1 > ... -> y -> j)
                #println(" --> Cas w2 vide")
                push!(operationsDrone, [ri, ry, rj]) # Le drone livre y puis rejoint le camion en j    
                for l in (z+1):(y-1) # On ne livre pas y
                    rw1_l1 = instance.solution.ordreVisiteCamion[l]
                    push!(ordreVisiteCamion, rw1_l1) # Le camion va en j directement   
                end
            end
        else # Opération drone
            noeudDrone = instance.solution.ordreVisiteCamion[operation]
            noeudDepart = instance.solution.ordreVisiteCamion[temp[i]]
            noeudFin = instance.solution.ordreVisiteCamion[temp[i+1]]
            push!(operationsDrone, [noeudDepart, noeudDrone, noeudFin]) # [i,k,j]
            for l in temp[i]+1:temp[i+1]-1
                noeudActu = instance.solution.ordreVisiteCamion[l]
                if noeudActu != noeudDrone # Noeud camion
                    push!(ordreVisiteCamion, noeudActu)
                end
            end
            push!(ordreVisiteCamion, noeudFin)
        end
    end
    
    instance.solution.tempsParcours = V[end]
    instance.solution.tempsAttente = A[end]
    instance.solution.ordreVisiteCamion = ordreVisiteCamion
    instance.solution.operationsDrone = operationsDrone
    instance.codeResolution = 4
end

