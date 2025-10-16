export class Member {
    constructor(name, firstName, team, imgSrc) {
        this.name = name;
        this.firstName = firstName;
        this.team = team;
        this.imgSrc = imgSrc;
        this.members = document.getElementById("members");
        this.initCard();
    }

    initCard() {
        const div = document.createElement("div");
        div.className = "fixed";

        const animate = document.createElement("div");
        animate.className = "memberCard"; // Commencer sans animation

        const imgDiv = document.createElement("div")
        imgDiv.style.backgroundImage =  "url('" +  this.imgSrc + "')";
        // const img = document.createElement("img");
        // img.src = this.imgSrc;
        // imgDiv.appendChild(img)

        const h2 = document.createElement("h2");
        h2.innerHTML = this.name + "<br>" + this.firstName;

        animate.append(imgDiv, h2);
        div.appendChild(animate);
        this.members.appendChild(div);

        // Forcer un reflow avant d'ajouter la classe d'animation
        animate.offsetHeight;

        // Ajouter la classe d'animation après un court délai
        setTimeout(() => {
            animate.classList.add("animate");
        }, 50);
    }
}