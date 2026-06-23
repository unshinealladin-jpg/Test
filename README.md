# ESP Shader — Minecraft 1.8.9 (OptiFine) — Through-Wall

Pack de shaders OptiFine qui implémente un **ESP complet** :
- Entités visibles normalement → silhouette colorée
- Entités derrière des blocs opaques → **ghost semi-transparent** (through-wall)
- Halo lumineux (glow) qui saigne autour des coins

## Installation

1. Installer **OptiFine** pour Minecraft 1.8.9
2. Copier le dossier `shaders/` ici :
   ```
   .minecraft/shaderpacks/ESP-Shader/shaders/
   ```
3. Lancer Minecraft → Options → Vidéo → Shaders → `ESP-Shader`

---

## Pipeline de rendu

```
gbuffers_skybasic/skytextured.fsh
  └── colortex0 = ciel | colortex2 = 1.0 (far plane)

gbuffers_terrain.fsh
  └── colortex0 = terrain | colortex2 = profondeur terrain réelle

gbuffers_entities.fsh  ← TRICK THROUGH-WALL
  ├── vertex shader : pos.z = -pos.w  (near-plane trick → depth test toujours OK)
  ├── colortex1 = masque (r=joueur, g=hostile, b=neutre, a=profondeur réelle)
  └── gl_FragDepth = v_realDepth      (restaure la vraie profondeur)

gbuffers_water/hand.fsh
  └── colortex0 = eau + main (pas d'entités)

composite.fsh
  └── blur gaussien horizontal colortex1.rgb → colortex3

composite1.fsh  ← LOGIQUE ESP
  ├── blur vertical colortex3 → glow final
  ├── compare entityDepth (colortex1.a) vs terrainDepth (colortex2.r)
  │     > entityDepth > terrainDepth → entité DERRIÈRE mur → ghost 40%
  │     > sinon                      → entité VISIBLE      → tint 50%
  └── ajoute glow additif coloré

final.fsh
  └── correction gamma + sortie
```

---

## Couleurs ESP

| Type       | Couleur        | Entités                              |
|------------|----------------|--------------------------------------|
| Joueur     | Bleu `#1A8CFF` | Autres joueurs                       |
| Hostile    | Rouge `#FF1A1A`| Zombie, Creeper, Skeleton, Enderman… |
| Neutre     | Vert `#1AFF40` | Cochon, Vache, Villageois…           |

---

## Réglages (`composite1.fsh`)

```glsl
const float BLUR_RADIUS    = 6.0;  // Taille du halo (pixels)
const float GLOW_STRENGTH  = 3.0;  // Intensité lumineuse du glow
const float VISIBLE_TINT   = 0.50; // Opacité ESP sur entité visible
const float GHOST_OPACITY  = 0.40; // Opacité ESP pour les entités à travers les murs
const float DEPTH_BIAS     = 0.002;// Seuil z-fighting
```

---

## Hotkey

Les shaders GLSL n'ont pas accès aux événements clavier — une hotkey
pure shader n'est pas possible. Deux alternatives :

1. **Touche par défaut OptiFine** : `K` désactive/réactive tous les shaders
   (Options → Vidéo → Shaders → raccourci configurable)
2. **Avec Forge** : ajouter un micro-mod qui envoie un uniform `espEnabled`
   au shader via `glUniform1i`, et le tester dans `composite1.fsh`

---

## Note technique

Le **near-plane trick** dans `gbuffers_entities.vsh` :
```glsl
pos.z = -pos.w; // NDC z = -1 → toujours au plan proche → depth test passe
```
permet aux fragments d'entités de ne jamais être éliminés par le depth test,
même derrière un bloc opaque. La vraie profondeur est ensuite restaurée via
`gl_FragDepth` pour ne pas casser le rendu de l'eau et de la main.
