function enregistrerInstance(instance, nom)
    sortie = open("instances/nous/bibliotheque_autres/"*nom, "w")
    write(sortie, string(instance.nbPoints))
    write(sortie, "\n"*string(instance.vitesseCamion)*" "*string(instance.vitesseDrone))
    for i in 1:size(instance.listePoints,1)
        write(sortie, "\n"*string(instance.listePoints[i].x)*" "*string(instance.listePoints[i].y))
    end
    close(sortie);
end

function onclick(event, listePoints, fig, ax)
    #println(" --> (",event.xdata,",",event.ydata,")")
    #push!(listePoints, [event.xdata, event.ydata])
    #println(listePoints)
    p = Point(event.xdata, event.ydata, string(size(listePoints,1) + 1))
    push!(listePoints, p)
    #graphe.append_xdata(event.xdata)
    #graphe.append_ydata(event.ydata)
    if size(listePoints,1) == 1 # Dépôt
        #ax.plot(event.xdata, event.ydata, ls="", marker="x", color="green", label="Dépôt") 
        ax.plot(event.xdata, event.ydata, ls="", marker="x", color="green", label="Depot") 
    elseif size(listePoints,1) == 2 # Premier client
        #ax.plot(event.xdata, event.ydata, ls="", marker="x", color="red", label="Clients") 
        ax.plot(event.xdata, event.ydata, ls="", marker="x", color="red", label="Customers") 
    else
        ax.plot(event.xdata, event.ydata, ls="", marker="x", color="red") 
    end
    ax.text(event.xdata+1.5, event.ydata+1.5, string(size(listePoints,1)))
    legend(loc="best") 
    fig.canvas.draw()
end

function instanceSurMesure(bool=true)
    listePoints = []
    fig = plt.figure()
    ax = fig.add_subplot(111) 
    #global graphe, = ax.plot([], marker="o")
    fig.canvas.mpl_connect("button_press_event", event -> onclick(event, listePoints, fig, ax))
    #title("Création d'une instance")
    title("Creating an instance")
    xlim(0,100)
    ylim(0,100)
    #xlabel("Coordonées x")
    xlabel("x")
    #ylabel("Coordonées y")
    ylabel("y")
    grid(true)
    show()

    print("\n --> Appuyez sur entrée pour valider...")
    readline()
    close()

    nbPoints = size(listePoints,1)
    D = Array{Float64,2}(undef, nbPoints, nbPoints)
    for i in 1:(nbPoints)
        for j in 1:(nbPoints)
            D[i,j] = distance(listePoints[i], listePoints[j])
        end
    end
    print("\n --> Vitesse du camion : ")
    vitesseCamion = readline()
    vitesseCamion = parse(Float64, vitesseCamion)
    print(" --> Vitesse du drone : ")
    vitesseDrone = readline()
    vitesseDrone = parse(Float64, vitesseDrone)

    solution = Solution([], [], 0, 0) # Solution du problème (= ordre de visite camion + opérations drone + temps parcours + temps attente total)
    instance = Instance(vitesseCamion, vitesseDrone, nbPoints, listePoints, D, solution, 0)

    if bool == true
        choix = choixBinaire("\n --> Souhaitez-vous enregistrer l'instance (o/n) ? ")
    else
        choix = "o"
    end

    if choix == "o"
        print(" --> Nom de l'instance : ")
        nom = readline()
        enregistrerInstance(instance, nom)
    end
    
    if bool == true
        return instance
    end
end





