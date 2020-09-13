using PyPlot
using CSV
include("structures.jl")
include("utilitaires.jl")
include("parser.jl")
include("concorde.jl")
include("partitionnement_mono.jl")

function mainExp()
    # Tous les types d'instances hormis Poikonen
    run(`clear`)
    println(" Type des instances :")
    println(" --------------------")  
    println("  1) Agatz")
    println("  2) Nous")
    println("  3) TSPLIB")
    println("  4) Poikonen")
    typeInstance = parse(Int64, choixListe(4))  
    if typeInstance == 4
        expPoiko()
    else
        expAutres(typeInstance)
    end
end

########## Agatz, TSPLIB, Nous ##########

function expAutres(typeInstance)
    f = open("rapport.tex", "w")
    # En-tête
    l = "\\documentclass{article}"
    l *= "\n\\usepackage[utf8]{inputenc}"
    l *= "\n\\usepackage[top=2cm, bottom=3cm, left=2.5cm, right=2.5cm]{geometry}"
    l *= "\n\\usepackage{float}"
    l *= "\n\\usepackage{graphicx}"
    l *= "\n\\usepackage{rotating}"
    l *= "\n\n\\begin{document}"
    l *= "\n\n\\hrule"
    l *= "\n\\begin{center}"
    l *= "\n\\Large{\\textbf{Experimentations}}"
    l *= "\n\\vspace{0.1mm}"
    l *= "\n\\end{center}"
    l *= "\n\\hrule \\vspace{8mm}"
    write(f, l)
  
    # Table des matières
    #l = "\n\n\\tableofcontents"
    #write(f, l)

    # Logo
    l = "\n\n\\vspace{4mm}\\begin{figure}[H]"
    l *= "\n\\center"
    l *= "\n\\includegraphics[scale=0.22]{logo/logo+.png}"   
    l *= "\n\\end{figure}"
    write(f, l)
  
    # Paramètres
    vitesseCamion = 1
    vitesseDrone = 3
    listeInstances = readdir("experimentations")
    nbInstances = length(listeInstances)
    l = "\n\n\\vspace{5mm}"
    l *= "\n\\section{Parameters}"
    l *= "\n\n\\begin{itemize}"
    l *= "\n    \\item Truck speed: \\textbf{"*string(vitesseCamion)*"}"
    l *= "\n    \\item Drone speed: \\textbf{"*string(vitesseDrone)*"}"
    l *= "\n    \\item Number of instances: \\textbf{"*string(nbInstances)*"}"
    l *= "\n\n\\end{itemize}"
    write(f, l)

    # Environnement
    println("\n Détection du matériel :")
    println(" -----------------------")
    os1 = read(`uname -s`, String) # Read permet de lire le résultat de la commande
    os2 = read(`uname -r`, String) 
    # Commande = uname -s -r
    systeme = read(`dmidecode -s system-product-name`, String) 
    # Commande = dmidecode -s system-product-name
    processeur = read(`dmidecode -s processor-version`, String)
    # Commande = dmidecode -s processor-version
    tailleMemoire = read(pipeline(`lshw -c memory`, pipeline(`grep taille:`, pipeline(`head -1`,  `awk   '{print $2}'`))), String)
    # Commande = lshw -c memory | grep taille: | head -1 | awk   '{print $2}'
    typeMemoire = read(pipeline(`lshw -c memory`, pipeline(`grep description:`, pipeline(`sed -n 2p`, `cut -c 24-`))), String)
    # Commande = lshw -c memory | grep description: | sed -n 2p | cut -c 24-
    l = "\n\n\\vspace{5mm}"
    l *= "\n\\section{Environment}"
    l *= "\n\n\\begin{itemize}"
    l *= "\n    \\item OS: \\textbf{"*os1*" - "*os2*"}"
    l *= "\n    \\item Manufacturer + Product: \\textbf{"*systeme*"}"
    l *= "\n    \\item CPU: \\textbf{"*processeur*"}"
    l *= "\n    \\item Memory: \\textbf{"*tailleMemoire*" "*typeMemoire*"}"
    l *= "\n    \\item Julia Version: \\textbf{"*string(VERSION)*"}"
    l *= "\n    \\item Code Verbosity: \\textbf{None}"
    l *= "\n\n\\end{itemize}"
    write(f, l)
    println(" --> OK")

  
    # Résultats en partant de Concorde TSP et avec AEP/EP
    l = "\n\n\\newpage"
    l *= "\n\n\\section{Results}"
    l *= "\n\\subsection{Optimal-TSP}"
    write(f, l)

    deb = 1
    premier = true
    nbTableaux = round(length(listeInstances)/32, RoundUp)
    println("\n Progression : ")
    println(" -------------")
    for i in 1:nbTableaux
        tableau(f, listeInstances, typeInstance, vitesseCamion, vitesseDrone, deb, premier, i, nbTableaux)
        deb += 32
        premier = false
    end

    # Résultats en partant de Concorde TSP vs. LKH TSP
    l = "\n\n\\newpage"
    l *= "\n\\subsection{Heuristic-TSP vs optimal-TSP}"
    write(f,l)

    deb = 1
    nbTableaux = round(length(listeInstances)/20, RoundUp)
    println("\n Progression (bis) : ")
    println(" ---------------------")
    for i in 1:nbTableaux
        tableauBis(f, listeInstances, typeInstance, vitesseCamion, vitesseDrone, deb, i, nbTableaux)
        deb += 20
        premier = false
    end

    ## Pied de page
    write(f, "\n\n\\end{document}")
    close(f)
    run(pipeline(`pdflatex rapport.tex`, stdout=devnull))
    #run(`pdflatex rapport.tex`) # Deuxième compilation pour la table des matières (nécessaire)
    run(`rm rapport.aux rapport.log`)
    run(`mv rapport.tex sorties/`)
    run(`mv rapport.pdf sorties/`)
    println("\n Le rapport est disponible dans le dossier \"sorties/\"")
end

function tableau(f, listeInstances, typeInstance, vitesseCamion, vitesseDrone, deb, premier, i, nbTableaux)
    ## En-tête tableau
    if premier == false # Tableaux suivants
        l = "\n\n\\newpage"   
    else
        l = ""
    end
    l *= "\n\n\\renewcommand{\\arraystretch}{1.4}"
    l *= "\n\\begin{table}[H]"
    l *= "\n\\hspace{-10mm}\\begin{tabular}{|c||c|c|c|c|c|c|c|c|c|c|}"
    l *= "\n\\cline{2-10}"
    l *= "\n\\multicolumn{1}{c|}{} & \\multicolumn{9}{|c|}{\\large{Computational Results - Overview ("*string(trunc(Int, i))*"/"*string(trunc(Int, nbTableaux))*")}} \\\\"
    l *= "\n\\cline{2-10}"
    l *= "\n\\multicolumn{1}{c|}{}& \\multicolumn{3}{|c}{\\textbf{TSP}} & \\multicolumn{3}{|c}{\\textbf{AEP (A1)}} & \\multicolumn{3}{|c|}{\\textbf{EP (A2)}} \\\\"
    l *= "\n\\hline"
    l *= "\n\\textbf{Instance} & \\textbf{\$z_1\$} & \\textbf{\$z_2\$} & \\textbf{Time (\$s\$)} & \\textbf{\$z_1\$} & \\textbf{\$z_2\$} & \\textbf{Time (\$s\$)} & \\textbf{\$z_1\$} & \\textbf{\$z_2\$} & \\textbf{Time (\$s\$)}  \\\\"
    l *= "\n\\hline"
    l *= "\n\\hline"
    write(f,l)

    # Corps
    compteur = 0 # Maximum 32 instances par page
    for i in deb:length(listeInstances)
        println(" --> "*string(i)*" : OK")
        if typeInstance == 1
            instance = parserAgatzBis(listeInstances[i])
        elseif typeInstance == 2
            instance = parserNousBis(listeInstances[i])
            # On échappe les "_" pour pouvoir les afficher ci-après
            listeInstances[i] = replace(listeInstances[i], "_"=>"\\_")
        elseif typeInstance == 3
            instance = parserTsplibBis(listeInstances[i])
        end
        instance.vitesseCamion = vitesseCamion
        instance.vitesseDrone = vitesseDrone
        temps = @elapsed concordeFast(instance)
        tspSolution = instance.solution.ordreVisiteCamion
        tspTempsParcours = instance.solution.tempsParcours # Pour ne pas refaire après
        l = "\n\\textit{\""*listeInstances[i]*"\"} & "*string(round(instance.solution.tempsParcours,digits=2))*" & "*string(round(instance.solution.tempsAttente,digits=2))*" & "*string(temps)
        temps = @elapsed AEP(instance)
        l *= " & "*string(round(instance.solution.tempsParcours,digits=2))*" & "*string(round(instance.solution.tempsAttente,digits=2))*" & "*string(temps)*" "
        instance.solution = Solution(tspSolution, [], tspTempsParcours, 0) # Reset
        temps = @elapsed EP(instance)
        l *= "& "*string(round(instance.solution.tempsParcours,digits=2))*" & "*string(round(instance.solution.tempsAttente,digits=2))*" & "*string(temps)*" \\\\"
        l *= "\n\\hline"
        write(f, l)
        compteur += 1
        if typeInstance == 2
            listeInstances[i] = replace(listeInstances[i], "\\_"=>"_")
        end
        if compteur == 32
            break
        end
    end

    ## Pied tableau
    l = "\n\\end{tabular}"
    l *= "\n\\end{table}"
    write(f, l)    
end

function tableauBis(f, listeInstances, typeInstance, vitesseCamion, vitesseDrone, deb, i, nbTableaux)
    ## En-tête tableau
    l = "\n\n\\renewcommand{\\arraystretch}{1.4}"
    l *= "\n\\begin{table}[H]"
    l *= "\n\\rotatebox{90}{\\begin{tabular}{|c||c|c|c|c|c|c|c|c|c|c|c|c|c|}"
    l *= "\n\\cline{2-13}"
    l *= "\n\\multicolumn{1}{c|}{} & \\multicolumn{12}{|c|}{\\large{Computational Results - Overview ("*string(trunc(Int, i))*"/"*string(trunc(Int, nbTableaux))*")}} \\\\"
    l *= "\n\\cline{2-13}"
    l *= "\n\\multicolumn{1}{c|}{} & \\multicolumn{6}{|c|}{\\textbf{TSP via Concorde}} & \\multicolumn{6}{|c|}{\\textbf{TSP via Linkern}}  \\\\"
    l *= "\n\\cline{2-13}"
    l *= "\n\\multicolumn{1}{c|}{} & \\multicolumn{3}{|c}{\\textbf{AEP (A1)}} & \\multicolumn{3}{|c|}{\\textbf{EP (A2)}} & \\multicolumn{3}{|c}{\\textbf{AEP (A1)}} & \\multicolumn{3}{|c|}{\\textbf{EP (A2)}} \\\\"
    l *= "\n\\hline"
    l *= "\n\\textbf{Instance} & \\textbf{\$z_1\$} & \\textbf{\$z_2\$} & \\textbf{T (\$s\$)} & \\textbf{\$z_1\$} & \\textbf{\$z_2\$} & \\textbf{T (\$s\$)} & \\textbf{\$z_1\$} & \\textbf{\$z_2\$} & \\textbf{T (\$s\$)} & \\textbf{\$z_1\$} & \\textbf{\$z_2\$} & \\textbf{T (\$s\$)} \\\\"
    l *= "\n\\hline"
    l *= "\n\\hline"
    write(f,l)

    # Corps
    compteur = 0 # Maximum 20 instances par page (format paysage)
    for i in deb:length(listeInstances)
        println(" --> "*string(i)*" : OK")
        if typeInstance == 1
            instance = parserAgatzBis(listeInstances[i])
        elseif typeInstance == 2
            instance = parserNousBis(listeInstances[i])
            # On échappe les "_" pour pouvoir les afficher ci-après
            listeInstances[i] = replace(listeInstances[i], "_"=>"\\_")
        elseif typeInstance == 3
            instance = parserTsplibBis(listeInstances[i])
        end
        instance.vitesseCamion = vitesseCamion
        instance.vitesseDrone = vitesseDrone
        l = "\n\\textit{\""*listeInstances[i]*"\"}"
        concordeFast(instance)
        tspSolution = instance.solution.ordreVisiteCamion
        tspTempsParcours = instance.solution.tempsParcours # Pour ne pas refaire après
        temps = @elapsed AEP(instance)
        l *= " & "*string(round(instance.solution.tempsParcours,digits=2))*" & "*string(round(instance.solution.tempsAttente,digits=2))*" & "*string(round(temps, digits=7))*" "
        instance.solution = Solution(tspSolution, [], tspTempsParcours, 0) # Reset
        temps = @elapsed EP(instance)
        l *= "& "*string(round(instance.solution.tempsParcours,digits=2))*" & "*string(round(instance.solution.tempsAttente,digits=2))*" & "*string(round(temps, digits=7))*" "
        # LKH
        instance.solution = Solution([], [], 0, 0)
        lkhFast(instance)
        tspSolution = instance.solution.ordreVisiteCamion
        tspTempsParcours = instance.solution.tempsParcours # Pour ne pas refaire après
        temps = @elapsed AEP(instance)
        l *= " & "*string(round(instance.solution.tempsParcours,digits=2))*" & "*string(round(instance.solution.tempsAttente,digits=2))*" & "*string(round(temps, digits=7))*" "
        instance.solution = Solution(tspSolution, [], tspTempsParcours, 0) # Reset
        temps = @elapsed EP(instance)
        l *= "& "*string(round(instance.solution.tempsParcours,digits=2))*" & "*string(round(instance.solution.tempsAttente,digits=2))*" & "*string(round(temps, digits=7))*" \\\\"
        l *= "\n\\hline"
        write(f, l)
        compteur += 1
        if compteur == 20
            break
        end
    end

    ## Pied tableau
    l = "\n\\end{tabular}}"
    l *= "\n\\end{table}"
    write(f, l)    
end






########## Poikonen ##########

function expPoiko()
    f = open("rapport.tex", "w")
    # En-tête
    l = "\\documentclass{article}"
    l *= "\n\\usepackage[utf8]{inputenc}"
    l *= "\n\\usepackage[top=2cm, bottom=3cm, left=2.5cm, right=2.5cm]{geometry}"
    l *= "\n\\usepackage{float}"
    l *= "\n\\usepackage{graphicx}"
    l *= "\n\n\\begin{document}"
    l *= "\n\n\\hrule"
    l *= "\n\\begin{center}"
    l *= "\n\\Large{\\textbf{Experimentations}}"
    l *= "\n\\vspace{0.1mm}"
    l *= "\n\\end{center}"
    l *= "\n\\hrule \\vspace{8mm}"
    write(f, l)
  
    # Table des matières
    #l = "\n\n\\tableofcontents"
    #write(f, l)

    # Logo
    l = "\n\n\\vspace{4mm}\\begin{figure}[H]"
    l *= "\n\\center"
    l *= "\n\\includegraphics[scale=0.22]{logo/logo+.png}"   
    l *= "\n\\end{figure}"
    write(f, l)

    # Lecture instance
    bibliotheque = readdir("experimentations")
    lignes = CSV.read("experimentations/"*bibliotheque[1], header=false) 
    println("\n Nombre d'instances : " * string(size(lignes,1)))
    print("\n --> Borne inférieure : ")
    borneInf = parse(Int64, readline())
    print(" --> Borne supérieure : ")
    borneSup = parse(Int64, readline())
  
    # Paramètres
    vitesseCamion = 1
    vitesseDrone = 3
    l = "\n\n\\vspace{5mm}"
    l *= "\n\\section{Parameters}"
    l *= "\n\n\\begin{itemize}"
    l *= "\n    \\item Truck speed: \\textbf{"*string(vitesseCamion)*"}"
    l *= "\n    \\item Drone speed: \\textbf{"*string(vitesseDrone)*"}"
    l *= "\n    \\item Number of instances: \\textbf{"*string(borneSup - borneInf + 1)*"}"
    l *= "\n\n\\end{itemize}"
    write(f, l)

    # Environnement
    println("\n Détection du matériel :")
    println(" -----------------------")
    os1 = read(`uname -s`, String) # Read permet de lire le résultat de la commande
    os2 = read(`uname -r`, String) 
    # Commande = uname -s -r
    systeme = read(`dmidecode -s system-product-name`, String) 
    # Commande = dmidecode -s system-product-name
    processeur = read(`dmidecode -s processor-version`, String)
    # Commande = dmidecode -s processor-version
    tailleMemoire = read(pipeline(`lshw -c memory`, pipeline(`grep taille:`, pipeline(`head -1`,  `awk   '{print $2}'`))), String)
    # Commande = lshw -c memory | grep taille: | head -1 | awk   '{print $2}'
    typeMemoire = read(pipeline(`lshw -c memory`, pipeline(`grep description:`, pipeline(`sed -n 2p`, `cut -c 24-`))), String)
    # Commande = lshw -c memory | grep description: | sed -n 2p | cut -c 24-
    l = "\n\n\\vspace{5mm}"
    l *= "\n\\section{Environment}"
    l *= "\n\n\\begin{itemize}"
    l *= "\n    \\item OS: \\textbf{"*os1*" - "*os2*"}"
    l *= "\n    \\item Manufacturer + Product: \\textbf{"*systeme*"}"
    l *= "\n    \\item CPU: \\textbf{"*processeur*"}"
    l *= "\n    \\item Memory: \\textbf{"*tailleMemoire*" "*typeMemoire*"}"
    l *= "\n    \\item Julia Version: \\textbf{"*string(VERSION)*"}"
    l *= "\n    \\item Code Verbosity: \\textbf{None}"
    l *= "\n\n\\end{itemize}"
    write(f, l)
    println(" --> OK")

    # Résultats en partant de Concorde TSP et avec AEP/EP
    l = "\n\n\\newpage"
    l *= "\n\n\\section{Results}"
    l *= "\n\\subsection{Optimal-TSP}"
    write(f, l)

    premier = true
    nbTableaux = round((borneSup - borneInf + 1)/32, RoundUp)
    println("\n Progression : ")
    println(" -------------")
    cpt = borneInf
    for i in 1:nbTableaux
        tableauPoiko(f, vitesseCamion, vitesseDrone, cpt, premier, i, nbTableaux, borneSup, lignes)
        cpt += 32
        premier = false
    end

    # Résultats en partant de Concorde TSP vs. LKH TSP
    l = "\n\n\\newpage"
    l *= "\n\\subsection{Heuristic-TSP vs optimal-TSP}"
    write(f,l)

    nbTableaux = round((borneSup - borneInf + 1)/20, RoundUp)
    println("\n Progression (bis) : ")
    println(" ---------------------")
    cpt = borneInf
    for i in 1:nbTableaux
        tableauPoikoBis(f, vitesseCamion, vitesseDrone, cpt, i, nbTableaux, borneSup, lignes)
        cpt += 20
        premier = false
    end


    ## Pied de page
    write(f, "\n\n\\end{document}")
    close(f)
    run(pipeline(`pdflatex rapport.tex`, stdout=devnull))
    #run(`pdflatex rapport.tex`) # Deuxième compilation pour la table des matières (nécessaire)
    run(`rm rapport.aux rapport.log`)
    run(`mv rapport.tex sorties/`)
    run(`mv rapport.pdf sorties/`)
    println("\n Le rapport est disponible dans le dossier \"sorties/\"")
end

function tableauPoiko(f, vitesseCamion, vitesseDrone, cpt, premier, i, nbTableaux, borneSup, lignes)
    ## En-tête tableau
    if premier == false # Tableaux suivants
        l = "\n\n\\newpage"   
    else
        l = ""
    end
    l *= "\n\n\\renewcommand{\\arraystretch}{1.4}"
    l *= "\n\\begin{table}[H]\n\\begin{center}"
    l *= "\n\\hspace{-10mm}\\begin{tabular}{|c||c|c|c|c|c|c|c|c|c|c|}"
    l *= "\n\\cline{2-10}"
    l *= "\n\\multicolumn{1}{c|}{} & \\multicolumn{9}{|c|}{\\large{Computational Results - Overview ("*string(trunc(Int, i))*"/"*string(trunc(Int, nbTableaux))*")}} \\\\"
    l *= "\n\\cline{2-10}"
    l *= "\n\\multicolumn{1}{c|}{} & \\multicolumn{3}{|c}{\\textbf{TSP}} & \\multicolumn{3}{|c}{\\textbf{AEP (A1)}} & \\multicolumn{3}{|c|}{\\textbf{EP (A2)}} \\\\"
    l *= "\n\\hline"
    l *= "\n\\textbf{Instance} & \\textbf{\$z_1\$} & \\textbf{\$z_2\$} & \\textbf{Time (\$s\$)} & \\textbf{\$z_1\$} & \\textbf{\$z_2\$} & \\textbf{Time (\$s\$)} & \\textbf{\$z_1\$} & \\textbf{\$z_2\$} & \\textbf{Time (\$s\$)}  \\\\"
    l *= "\n\\hline"
    l *= "\n\\hline"
    write(f,l)

    # Corps
    compteur = 0 # Maximum 32 instances par page
    for i in cpt:borneSup
        println(" --> "*string(i)*" : OK")
        instance = parserPoikoBis(lignes, i)
        instance.vitesseCamion = vitesseCamion
        instance.vitesseDrone = vitesseDrone
        temps = @elapsed concordeFast(instance)
        l = "\n\\textit{\"instance\\_"*string(i)*"\"} & "*string(round(instance.solution.tempsParcours,digits=2))*" & "*string(round(instance.solution.tempsAttente,digits=2))*" & "*string(temps)
        temps = @elapsed AEP(instance)
        l *= " & "*string(round(instance.solution.tempsParcours,digits=2))*" & "*string(round(instance.solution.tempsAttente,digits=2))*" & "*string(temps)*" "
        instance.solution = Solution([], [], 0, 0) # Reset
        concordeFast(instance)
        temps = @elapsed EP(instance)
        l *= "& "*string(round(instance.solution.tempsParcours,digits=2))*" & "*string(round(instance.solution.tempsAttente,digits=2))*" & "*string(temps)*" \\\\"
        l *= "\n\\hline"
        write(f, l)
        compteur += 1
        if compteur == 32
            break
        end
    end

    ## Pied tableau
    l = "\n\\end{tabular}\n\\end{center}"
    l *= "\n\\end{table}"
    write(f, l)    
end

function tableauPoikoBis(f, vitesseCamion, vitesseDrone, cpt, i, nbTableaux, borneSup, lignes)
    ## En-tête tableau
    l = "\n\n\\renewcommand{\\arraystretch}{1.4}"
    l *= "\n\\begin{table}[H]"
    l *= "\n\\rotatebox{90}{\\begin{tabular}{|c||c|c|c|c|c|c|c|c|c|c|c|c|c|}"
    l *= "\n\\cline{2-13}"
    l *= "\n\\multicolumn{1}{c|}{} & \\multicolumn{12}{|c|}{\\large{Computational Results - Overview ("*string(trunc(Int, i))*"/"*string(trunc(Int, nbTableaux))*")}} \\\\"
    l *= "\n\\cline{2-13}"
    l *= "\n\\multicolumn{1}{c|}{} & \\multicolumn{6}{|c|}{\\textbf{TSP via Concorde}} & \\multicolumn{6}{|c|}{\\textbf{TSP via Linkern}}  \\\\"
    l *= "\n\\cline{2-13}"
    l *= "\n\\multicolumn{1}{c|}{} & \\multicolumn{3}{|c}{\\textbf{AEP (A1)}} & \\multicolumn{3}{|c|}{\\textbf{EP (A2)}} & \\multicolumn{3}{|c}{\\textbf{AEP (A1)}} & \\multicolumn{3}{|c|}{\\textbf{EP (A2)}} \\\\"
    l *= "\n\\hline"
    l *= "\n\\textbf{Instance} & \\textbf{\$z_1\$} & \\textbf{\$z_2\$} & \\textbf{T (\$s\$)} & \\textbf{\$z_1\$} & \\textbf{\$z_2\$} & \\textbf{T (\$s\$)} & \\textbf{\$z_1\$} & \\textbf{\$z_2\$} & \\textbf{T (\$s\$)} & \\textbf{\$z_1\$} & \\textbf{\$z_2\$} & \\textbf{T (\$s\$)} \\\\"
    l *= "\n\\hline"
    l *= "\n\\hline"
    write(f,l)

    # Corps
    compteur = 0 # Maximum 20 instances par page (format paysage)
    for i in cpt:borneSup
        println(" --> "*string(i)*" : OK")
        instance = parserPoikoBis(lignes, i)
        instance.vitesseCamion = vitesseCamion
        instance.vitesseDrone = vitesseDrone
        l = "\n\\textit{\"instance\\_"*string(i)*"\"}"
        concordeFast(instance)
        tspSolution = instance.solution.ordreVisiteCamion
        tspTempsParcours = instance.solution.tempsParcours # Pour ne pas refaire après
        temps = @elapsed AEP(instance)
        l *= " & "*string(round(instance.solution.tempsParcours,digits=2))*" & "*string(round(instance.solution.tempsAttente,digits=2))*" & "*string(round(temps, digits=7))*" "
        instance.solution = Solution(tspSolution, [], tspTempsParcours, 0) # Reset
        temps = @elapsed EP(instance)
        l *= "& "*string(round(instance.solution.tempsParcours,digits=2))*" & "*string(round(instance.solution.tempsAttente,digits=2))*" & "*string(round(temps, digits=7))*" "
        # LKH
        instance.solution = Solution([], [], 0, 0)
        lkhFast(instance)
        tspSolution = instance.solution.ordreVisiteCamion
        tspTempsParcours = instance.solution.tempsParcours # Pour ne pas refaire après
        temps = @elapsed AEP(instance)
        l *= " & "*string(round(instance.solution.tempsParcours,digits=2))*" & "*string(round(instance.solution.tempsAttente,digits=2))*" & "*string(round(temps, digits=7))*" "
        instance.solution = Solution(tspSolution, [], tspTempsParcours, 0) # Reset
        temps = @elapsed EP(instance)
        l *= "& "*string(round(instance.solution.tempsParcours,digits=2))*" & "*string(round(instance.solution.tempsAttente,digits=2))*" & "*string(round(temps, digits=7))*" \\\\"
        l *= "\n\\hline"
        write(f, l)
        compteur += 1
        if compteur == 20
            break
        end
    end

    ## Pied tableau
    l = "\n\\end{tabular}}"
    l *= "\n\\end{table}"
    write(f, l)    
end

mainExp()
