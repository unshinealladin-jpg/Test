# ESP Shader — Minecraft 1.8.9 (OptiFine) — Through-Wall

Pack de shaders OptiFine qui colore les entités et les rend visibles à
travers les murs, avec un contour coloré.

## Installation

1. Installer **OptiFine** pour Minecraft 1.8.9
2. Copier le dossier `shaders/` dans :
   ```
   .minecraft/shaderpacks/ESP-Shader/shaders/
   ```
3. Lancer Minecraft → Options → Vidéo → Shaders → `ESP-Shader`

---

## Architecture (minimale et robuste)

Seuls 3 programmes sont surchargés. Le terrain, l'eau, le ciel et la main
utilisent les shaders par défaut d'OptiFine (c'est ce qui évite l'écran
blanc des versions précédentes).

```
gbuffers_entities.vsh   ← WALLHACK
  └── pos.z = -pos.w  (near-plane trick : l'entité passe toujours le depth
       test → dessinée par-dessus le terrain, visible à travers les murs)

gbuffers_entities.fsh
  ├── colortex0 = corps de l'entité teinté avec la couleur ESP
  └── colortex1 = masque (r=joueur, g=hostile, b=neutre) pour le contour
  (NE restaure PAS gl_FragDepth → l'entité reste à travers les murs)

composite.fsh
  └── détection de bord sur colortex1 → trace le contour coloré

final.fsh
  └── sortie écran (passthrough)
```

### Pourquoi l'écran était blanc avant

L'ancienne version surchargeait le terrain/ciel et stockait la profondeur
dans un buffer couleur 8-bit (`colortex2`), ce qui sur OptiFine 1.8.9
quantifiait tout à ~1.0 et, combiné à un glow additif, saturait l'écran en
blanc. De plus `gl_FragDepth = v_realDepth` annulait le wallhack. Les deux
bugs sont corrigés ici.

---

## Couleurs ESP

| Type    | Couleur        | Entités                              |
|---------|----------------|--------------------------------------|
| Joueur  | Bleu `#33B3FF` | Autres joueurs                       |
| Hostile | Rouge `#FF3333`| Zombie, Creeper, Skeleton, Enderman… |
| Neutre  | Vert `#33FF59` | Cochon, Vache, Villageois…           |

---

## Réglages

Teinte du corps de l'entité — `gbuffers_entities.fsh` :
```glsl
const float BODY_TINT = 0.55; // 0 = texture réelle, 1 = couleur ESP pleine
```

Épaisseur du contour — `composite.fsh` :
```glsl
const float OUTLINE_WIDTH = 2.0; // pixels
```

---

## Hotkey

Les shaders n'ont pas accès au clavier. Pour activer/désactiver :
touche **`K`** d'OptiFine (active/désactive tous les shaders).
