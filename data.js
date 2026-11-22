// All images are hosted on Cloudflare Pages.
window.IMG_BASE = "https://muse-cdn-ao2.pages.dev/img";

window.CHARACTERS = [
  {
    id: "sol",
    name: "Sol",
    handle: "@sol.studio",
    creator: "Ama Okafor",
    creatorHandle: "@ama.builds",
    tagline: "Warm light, quiet confidence.",
    bio: "A portrait-first AI character built around sepia tones and soft studio light. Sol shares moods, not products.",
    followers: "128K",
    following: "212",
    tags: ["Portrait", "Studio", "Sepia"],
    captions: ["Golden hour, indoors", "Hands tell the story", "Turtleneck season", "A laugh, unposed", "Low light study", "Close, closer"]
  },
  {
    id: "noor",
    name: "Noor",
    handle: "@noor.frames",
    creator: "Daniel Reyes",
    creatorHandle: "@reyes.lab",
    tagline: "Painted backdrops, old-world stillness.",
    bio: "Noor lives somewhere between a Dutch painting and a film still. Every frame is composed like a canvas.",
    followers: "96.4K",
    following: "88",
    tags: ["Fine art", "Portrait", "Painterly"],
    captions: ["Study in lilac", "The chair series", "Wind, indoors", "Shoulder light", "Canvas no. 5", "After the sitting"]
  },
  {
    id: "vera",
    name: "Vera",
    handle: "@vera.daily",
    creator: "Lena Marsh",
    creatorHandle: "@northfold",
    tagline: "City uniform: black, white, polka dot.",
    bio: "A street-style AI brand. Vera tests outfits against architecture and posts the ones that hold up.",
    followers: "211K",
    following: "340",
    tags: ["Street", "Fashion", "Monochrome"],
    captions: ["Columns and dots", "Saturday uniform", "Chain strap, black bag", "Museum steps", "Off duty", "One more take"]
  }
];

// Six pins per character, served from Cloudflare.
window.PINS = window.CHARACTERS.flatMap(c =>
  c.captions.map((caption, i) => ({
    id: `${c.id}-${i + 1}`,
    character: c.id,
    src: `${window.IMG_BASE}/${c.id}-${i + 1}.jpg`,
    caption,
    saves: Math.round(800 + ((i * 7919 + c.id.length * 104729) % 9000))
  }))
);
