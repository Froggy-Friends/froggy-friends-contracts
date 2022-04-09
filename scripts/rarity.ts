import fs from 'fs';
import * as data from '../rarity.json';

interface RarityBands {
    common: number[];
    uncommon: number[];
    rare: number[];
    legendary: number[];
    epic: number[];
}

let rarityBands: RarityBands = {
    common: [],
    uncommon: [],
    rare: [],
    legendary: [],
    epic: []
}

async function parseRarity() {
    for (const rarity of data.rarity) {
        if (rarity.rank < 9) {
            rarityBands.epic.push(+rarity.id);
        } else if (rarity.rank < 301) {
            rarityBands.legendary.push(+rarity.id);
        } else if (rarity.rank < 1001) {
            rarityBands.rare.push(+rarity.id);
        } else if (rarity.rank < 2001) {
            rarityBands.uncommon.push(+rarity.id);
        } else {
            rarityBands.common.push(+rarity.id);
        }
    }
    console.log("epic: ", rarityBands.epic.length);
    console.log("legendary: ", rarityBands.legendary.length);
    console.log("rare: ", rarityBands.rare.length);
    console.log("uncommon: ", rarityBands.uncommon.length);
    console.log("common: ", rarityBands.common.length);
}

parseRarity();
fs.writeFileSync('rarityBands.json', JSON.stringify(rarityBands));