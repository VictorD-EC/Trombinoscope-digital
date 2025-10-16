import { Member } from "./Member.js"

const actu = document.getElementById("actu")
const trombinoscope = document.getElementById("trombinoscope")
const members = document.getElementById("members")
const teamH2 = document.querySelector("#teamCard h2")

async function loadDatas() {
    try {
        const response = await fetch('./datas.json');
        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Erreur lors du chargement du fichier JSON:', error);
        return null;
    }
}

let data = null;
let teamMembers = {};
let allTeams = [];
let currentTeamIndex = 0;
let currentActuIndex = 0;
let runningLoop = true;

async function initialize() {
    data = await loadDatas();
    
    if (!data || !data.services) {
        console.error('Aucune donnée chargée');
        return;
    }

    allTeams = data.services.map(service => service.name);
    console.log("Services détectés :", allTeams);

    if (allTeams.length === 0) {
        console.error('Aucun service détecté');
        return;
    }

    initializeTeamMembers();
    runRotation();
}

function initializeTeamMembers() {
    teamMembers = {};
    data.services.forEach(service => {
        teamMembers[service.name] = [...service.collaborateurs];
    });
    console.log("Membres par service :", teamMembers);
}

function clearMembersDisplay() {
    members.innerHTML = '';
}

function updateActuDisplay() {
    if (!data.actualites || data.actualites.length === 0) return;
    
    actu.innerHTML = '';
    const currentActu = data.actualites[currentActuIndex];
    
    if (currentActu.type.toLowerCase() === 'pdf') {
        const iframe = document.createElement('iframe');
        iframe.src = `./${currentActu.fichier}`;  // Ajout de ./ pour le chemin relatif
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.style.border = 'none';
        actu.appendChild(iframe);
    } else {
        const img = document.createElement('img');
        img.src = `./${currentActu.fichier}`;  // Ajout de ./ pour le chemin relatif
        img.alt = currentActu.titre;
        img.style.maxWidth = '100%';
        img.style.maxHeight = '100%';
        img.style.objectFit = 'contain';
        actu.appendChild(img);
    }
    
    currentActuIndex = (currentActuIndex + 1) % data.actualites.length;
}

function showActu() {
    trombinoscope.classList.add("hidden");
    actu.classList.remove("hidden");
    updateActuDisplay();
}

async function displayPerson(person) {
    if (!person) return;

    trombinoscope.classList.remove("hidden");
    actu.classList.add("hidden");

    console.log(`Affichage de ${person.nom} avec la photo ${person.photo}`);

    let member = new Member(
        person.nom,
        "",
        "",
        `./${person.photo}`  // Ajout de ./ pour le chemin relatif
    );
}

async function displayTeamMembers(teamName) {
    if (!teamMembers[teamName] || teamMembers[teamName].length === 0) {
        console.warn(`Aucun membre restant pour le service ${teamName}`);
        return false;
    }

    clearMembersDisplay();
    teamH2.textContent = teamName;

    const membersToDisplay = teamMembers[teamName].splice(0, 12);
    console.log(`Affichage de ${membersToDisplay.length} membres du service ${teamName} (${teamMembers[teamName].length} restants)`);

    for (let i = 0; i < membersToDisplay.length && runningLoop; i++) {
        await displayPerson(membersToDisplay[i]);
        await new Promise(resolve => setTimeout(resolve, 300));
    }

    await new Promise(resolve => setTimeout(resolve, 5000));
    return true;
}

async function runRotation() {
    while (runningLoop) {
        try {
            showActu();
            await new Promise(resolve => setTimeout(resolve, 5000));

            if (!runningLoop) break;

            let teamHasMembers = false;
            let initialTeamIndex = currentTeamIndex;

            do {
                const currentTeam = allTeams[currentTeamIndex];
                teamHasMembers = await displayTeamMembers(currentTeam);

                if (!teamHasMembers) {
                    currentTeamIndex = (currentTeamIndex + 1) % allTeams.length;
                }

                if (currentTeamIndex === initialTeamIndex && !teamHasMembers) {
                    console.log("Tous les services ont été parcourus, réinitialisation des membres");
                    initializeTeamMembers();
                    break;
                }

            } while (!teamHasMembers && runningLoop);

            currentTeamIndex = (currentTeamIndex + 1) % allTeams.length;

        } catch (error) {
            console.error('Erreur dans la rotation:', error);
            await new Promise(resolve => setTimeout(resolve, 3000));
        }
    }
}

initialize();