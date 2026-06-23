# ESP Shader — Minecraft 1.8.9 (OptiFine)

Pack de shaders OptiFine qui ajoute un **ESP visuel** : les entités (joueurs, mobs) sont colorées et entourées d'un halo lumineux coloré.

## Installation

1. Installer **OptiFine** pour Minecraft 1.8.9
2. Copier le dossier `shaders/` dans :
   ```
   .minecraft/shaderpacks/ESP-Shader/shaders/
   ```
3. Lancer Minecraft → Options → Vidéo → Shaders → sélectionner `ESP-Shader`

---

## Fichiers

```
shaders/
├── shaders.properties       # Configuration du pack
│
├── gbuffers_terrain.vsh/fsh # Terrain : rendu normal, masque ESP = 0
├── gbuffers_entities.vsh/fsh# ENTITÉS : rendu + écriture du masque ESP
├── gbuffers_water.vsh/fsh   # Eau : rendu normal, masque ESP = 0
├── gbuffers_hand.vsh/fsh    # Main du joueur : pas d'ESP
│
├── composite.vsh/fsh        # Passe 1 : blur gaussien horizontal du masque
├── composite1.vsh/fsh       # Passe 2 : blur vertical + application du glow
└── final.vsh/fsh            # Sortie finale avec correction gamma
```

---

## Pipeline de rendu ESP

```
gbuffers_entities.fsh
  └── écrit colortex1 (masque : r=joueur, g=hostile, b=neutre)

composite.fsh
  └── blur horizontal de colortex1 → colortex2

composite1.fsh
  ├── blur vertical de colortex2 → glow final
  ├── teinte les pixels d'entité à 45% avec la couleur ESP
  └── ajoute le halo lumineux en mode additif

final.fsh
  └── correction gamma et sortie écran
```

---

## Couleurs ESP

| Type            | Couleur       | Entités                             |
|-----------------|---------------|-------------------------------------|
| Joueur (`id=1`) | Bleu `#1A8CFF`| Autres joueurs                      |
| Hostile         | Rouge `#FF1A1A`| Zombie, Creeper, Skeleton, Enderman… |
| Neutre          | Vert `#1AFF40` | Cochon, Vache, Mouton…              |

---

## Réglages (dans `composite1.fsh`)

```glsl
const float BLUR_RADIUS  = 4.0;   // Taille du halo en pixels
const float GLOW_STRENGTH = 2.8;  // Intensité lumineuse du glow
```

Augmenter `BLUR_RADIUS` pour un halo plus grand (plus visible à longue distance).  
Augmenter `GLOW_STRENGTH` pour un glow plus lumineux.

---

## Limitation importante

Les shaders OptiFine fonctionnent en **post-processing écran** : les fragments d'entités derrière des blocs opaques sont rejetés par le depth test avant d'atteindre le shader. L'ESP est donc visible pour :
- Les entités **partiellement visibles** (dépassant d'un mur)
- Les entités vues à travers des blocs **transparents** (verre, eau, glace)

Pour un ESP "à travers les murs opaques", un mod Forge avec injection du pipeline OpenGL est requis.
