# ESP Shader — Minecraft 1.8.9 Forge Mod

Mod Forge pour Minecraft 1.8.9 qui implémente un **ESP (Extra Sensory Perception)** via des shaders GLSL.  
Les entités (joueurs, mobs) sont visibles à travers les blocs avec un rendu coloré semi-transparent + contour.

---

## Structure du projet

```
src/
└── main/
    ├── java/com/espshader/
    │   ├── ESPMod.java              # Point d'entrée Forge
    │   ├── ESPEventHandler.java     # Hooks rendu & clavier
    │   └── shader/
    │       ├── ShaderProgram.java   # Chargement / compilation GLSL
    │       └── ESPShaderRenderer.java  # Rendu ESP (3 passes OpenGL)
    └── resources/
        ├── mcmod.info
        └── assets/espshader/shaders/
            ├── esp.vert             # Vertex shader (outline extrusion)
            └── esp.frag             # Fragment shader (colorisation)
```

---

## Fonctionnement des shaders

### `esp.vert` — Vertex Shader
- Extrude les sommets le long de la normale en clip-space pour générer l'épaisseur du contour (`outlineWidth`).

### `esp.frag` — Fragment Shader
- `fillMode = true`  → couleur ESP semi-transparente (silhouette de l'entité).
- `fillMode = false` → couleur ESP opaque (outline du contour extrudé).

### Stratégie de rendu en 2 passes (dans `ESPShaderRenderer`)
1. **Passe fill** : depth test désactivé + shader couleur semi-transparente → silhouette visible à travers les murs.
2. **Passe outline** : outline extrudé opaque → contour net coloré.

---

## Couleurs par défaut

| Type d'entité | Couleur        |
|---------------|----------------|
| Joueur        | Bleu `#0078FF` |
| Mob hostile   | Rouge `#FF2828` |
| Neutre        | Vert `#28FF28` |

---

## Contrôles

| Touche | Action                   |
|--------|--------------------------|
| `HOME` | Activer / Désactiver ESP |

---

## Compilation

Prérequis : **JDK 8**, **Gradle**, **Minecraft Forge 1.8.9-11.15.1.2318**

```bash
# Setup Forge (première fois uniquement)
./gradlew setupDecompWorkspace

# Compiler le mod
./gradlew build

# Le .jar se trouve dans build/libs/
```

---

## Configuration API

```java
ESPShaderRenderer renderer = ESPShaderRenderer.getInstance();

renderer.setEnabled(true);
renderer.setOutlineWidth(2.0f);
renderer.setColorPlayer(new Color(0, 200, 255, 220));
renderer.setColorEnemy(new Color(255, 50, 50, 220));
renderer.setColorNeutral(new Color(50, 255, 50, 220));
```
