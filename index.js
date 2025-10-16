import { Member } from "./Member.js"

const actu = document.getElementById("actu")
const trombinoscope = document.getElementById("trombinoscope")
const members = document.getElementById("members")

const teamH2 = document.querySelector("#teamCard h2")

async function loadDatas() {
    try {
        const response = await fetch('./assets/members.json');
        const data = await response.json();
        return data.data || data;
    } catch (error) {
        console.error('Erreur lors du chargement du fichier JSON:', error);
        return [];
    }
}

let allMembers = [];
let teamMembers = {}; // Objet pour stocker les membres par équipe
let allTeams = [];
let currentTeamIndex = 0;
let runningLoop = true;

async function initialize() {
    allMembers = await loadDatas();
    console.log(allMembers);
    if (allMembers.length === 0) {
        console.error('Aucune donnée chargée');
        return;
    }

    // Extraire tous les tags uniques (équipes) des membres
    allTeams = [...new Set(allMembers.map(member => member.tag).filter(tag => tag))];
    console.log("Équipes détectées :", allTeams);

    if (allTeams.length === 0) {
        console.error('Aucune équipe détectée');
        return;
    }

    // Initialiser les membres par équipe
    initializeTeamMembers();

    runRotation();
}

function initializeTeamMembers() {
    // Créer un objet qui contient les membres de chaque équipe
    teamMembers = {};

    allTeams.forEach(team => {
        teamMembers[team] = allMembers.filter(member => member.tag === team);
    });

    console.log("Membres par équipe :", teamMembers);
}

function clearMembersDisplay() {
    members.innerHTML = '';
}

function showActu() {
    trombinoscope.classList.add("hidden");
    actu.classList.remove("hidden");
}

async function displayPerson(person) {
    if (!person) return;

    trombinoscope.classList.remove("hidden");
    actu.classList.add("hidden");

    let numImg = Math.floor(Math.random() * 27).toString();
    console.log(`Affichage de ${person.firstname} ${person.name} avec l'image ${numImg}`);

    let imgSrc = './assets/avatars/' + numImg + '.jpg';

    let member = new Member(person.name, person.firstname, person.tag, imgSrc);
}

async function displayTeamMembers(teamTag) {
    // Vérifier si l'équipe a des membres
    if (!teamMembers[teamTag] || teamMembers[teamTag].length === 0) {
        console.warn(`Aucun membre restant pour l'équipe ${teamTag}`);
        return false; // Indiquer qu'il n'y a plus de membres
    }

    clearMembersDisplay();
    teamH2.textContent = "Team - " + teamTag;

    // Prendre jusqu'à 12 membres maximum
    const membersToDisplay = teamMembers[teamTag].splice(0, 12);
    console.log(`Affichage de ${membersToDisplay.length} membres de l'équipe ${teamTag} (${teamMembers[teamTag].length} restants)`);

    // Afficher les membres un par un avec une animation
    for (let i = 0; i < membersToDisplay.length && runningLoop; i++) {
        await displayPerson(membersToDisplay[i]);
        await new Promise(resolve => setTimeout(resolve, 300));
    }

    // Attendre 10 secondes après avoir affiché tous les membres
    await new Promise(resolve => setTimeout(resolve, 5000));

    return true; // Indiquer que des membres ont été affichés
}

async function runRotation() {
    while (runningLoop) {
        try {
            // Afficher l'actualité pendant 5 secondes
            showActu();
            await new Promise(resolve => setTimeout(resolve, 5000));

            if (!runningLoop) break;

            let teamHasMembers = false;
            let initialTeamIndex = currentTeamIndex;

            // Essayer les équipes une par une jusqu'à en trouver une avec des membres
            do {
                const currentTeam = allTeams[currentTeamIndex];
                teamHasMembers = await displayTeamMembers(currentTeam);

                // Si aucun membre n'a été affiché, passer à l'équipe suivante
                if (!teamHasMembers) {
                    currentTeamIndex = (currentTeamIndex + 1) % allTeams.length;
                }

                // Si on a fait le tour de toutes les équipes sans trouver de membres
                if (currentTeamIndex === initialTeamIndex && !teamHasMembers) {
                    console.log("Toutes les équipes ont été parcourues, réinitialisation des membres");
                    initializeTeamMembers();
                    break;
                }

            } while (!teamHasMembers && runningLoop);

            // Passer à l'équipe suivante pour la prochaine itération
            currentTeamIndex = (currentTeamIndex + 1) % allTeams.length;

        } catch (error) {
            console.error('Erreur dans la rotation:', error);
            await new Promise(resolve => setTimeout(resolve, 3000));
        }
    }
}

// Démarrer l'application
initialize();