package com.espshader.shader;

import com.espshader.ESPMod;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.GlStateManager;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityLivingBase;
import net.minecraft.entity.monster.EntityMob;
import net.minecraft.entity.player.EntityPlayer;
import org.lwjgl.opengl.GL11;

import java.awt.Color;

/**
 * Singleton responsable du rendu ESP via les shaders GLSL.
 *
 * Stratégie de rendu en 3 passes :
 *   1. Rendu normal avec depth test (l'entité visible normalement).
 *   2. Rendu sans depth test avec shader couleur pleine (entité à travers les murs).
 *   3. Rendu outline extrudé avec shader pour le contour coloré.
 */
public class ESPShaderRenderer {

    private static ESPShaderRenderer instance;

    private ShaderProgram espShader;
    private boolean initialized = false;

    // Couleurs ESP configurables
    private Color colorPlayer  = new Color(0, 120, 255, 200);  // Bleu pour les joueurs
    private Color colorEnemy   = new Color(255, 40,  40, 200);  // Rouge pour les mobs hostiles
    private Color colorNeutral = new Color(40,  255, 40, 200);  // Vert pour les entités neutres

    private float outlineWidth = 1.5f;
    private boolean enabled    = true;

    private ESPShaderRenderer() {}

    public static ESPShaderRenderer getInstance() {
        if (instance == null) instance = new ESPShaderRenderer();
        return instance;
    }

    /** Charge les shaders depuis les ressources du mod. */
    public void init() {
        espShader = new ShaderProgram(
            ESPMod.MODID,
            "shaders/esp.vert",
            "shaders/esp.frag"
        );

        if (espShader.load()) {
            initialized = true;
            ESPMod.LOGGER.info("ESP Shader Renderer initialisé.");
        } else {
            ESPMod.LOGGER.error("Impossible de charger le shader ESP.");
        }
    }

    /**
     * Effectue le rendu ESP d'une entité.
     * Doit être appelé depuis RenderLivingEvent.Pre ou Post dans le thread de rendu.
     */
    public void renderESP(Entity entity, double x, double y, double z) {
        if (!enabled || !initialized || !espShader.isLoaded()) return;

        // Ne pas se rendre soi-même en ESP
        EntityPlayer localPlayer = Minecraft.getMinecraft().thePlayer;
        if (entity == localPlayer) return;

        Color color = getColorForEntity(entity);

        // --- Sauvegarde de l'état OpenGL ---
        GL11.glPushAttrib(GL11.GL_ALL_ATTRIB_BITS);
        GL11.glPushMatrix();

        GL11.glTranslated(x, y, z);

        // Désactivation du depth test pour voir à travers les blocs
        GlStateManager.disableDepth();
        GL11.glDepthMask(false);

        // Blending pour la transparence
        GlStateManager.enableBlend();
        GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE_MINUS_SRC_ALPHA);

        // Désactivation de l'éclairage et des textures pour le rendu shader
        GlStateManager.disableLighting();
        GlStateManager.disableTexture2D();
        GlStateManager.disableCull();

        // --- Passe 1 : remplissage semi-transparent (fill) ---
        espShader.bind();
        espShader.setUniform4f("espColor",
            color.getRed()   / 255f,
            color.getGreen() / 255f,
            color.getBlue()  / 255f,
            color.getAlpha() / 255f
        );
        espShader.setUniform1f("outlineWidth", 0f);
        espShader.setUniform1b("fillMode", true);

        renderEntityBoundingBox(entity);

        // --- Passe 2 : outline extrudé ---
        espShader.setUniform1f("outlineWidth", outlineWidth);
        espShader.setUniform1b("fillMode", false);
        espShader.setUniform4f("espColor",
            color.getRed()   / 255f,
            color.getGreen() / 255f,
            color.getBlue()  / 255f,
            1.0f  // Outline toujours opaque
        );

        renderEntityBoundingBox(entity);

        ShaderProgram.unbind();

        // --- Restauration de l'état OpenGL ---
        GlStateManager.enableCull();
        GlStateManager.enableTexture2D();
        GlStateManager.enableLighting();
        GlStateManager.enableDepth();
        GL11.glDepthMask(true);
        GlStateManager.disableBlend();

        GL11.glPopMatrix();
        GL11.glPopAttrib();
    }

    /** Rendu d'un bounding box en quads représentant la silhouette de l'entité. */
    private void renderEntityBoundingBox(Entity entity) {
        float w = (float) entity.width  / 2f;
        float h = (float) entity.height;

        GL11.glBegin(GL11.GL_QUADS);

        // Face avant
        GL11.glNormal3f(0f, 0f, 1f);
        GL11.glVertex3f(-w,  0, -w);
        GL11.glVertex3f( w,  0, -w);
        GL11.glVertex3f( w,  h, -w);
        GL11.glVertex3f(-w,  h, -w);

        // Face arrière
        GL11.glNormal3f(0f, 0f, -1f);
        GL11.glVertex3f( w,  0,  w);
        GL11.glVertex3f(-w,  0,  w);
        GL11.glVertex3f(-w,  h,  w);
        GL11.glVertex3f( w,  h,  w);

        // Face gauche
        GL11.glNormal3f(-1f, 0f, 0f);
        GL11.glVertex3f(-w,  0,  w);
        GL11.glVertex3f(-w,  0, -w);
        GL11.glVertex3f(-w,  h, -w);
        GL11.glVertex3f(-w,  h,  w);

        // Face droite
        GL11.glNormal3f(1f, 0f, 0f);
        GL11.glVertex3f( w,  0, -w);
        GL11.glVertex3f( w,  0,  w);
        GL11.glVertex3f( w,  h,  w);
        GL11.glVertex3f( w,  h, -w);

        // Face haut
        GL11.glNormal3f(0f, 1f, 0f);
        GL11.glVertex3f(-w,  h, -w);
        GL11.glVertex3f( w,  h, -w);
        GL11.glVertex3f( w,  h,  w);
        GL11.glVertex3f(-w,  h,  w);

        // Face bas
        GL11.glNormal3f(0f, -1f, 0f);
        GL11.glVertex3f(-w,  0,  w);
        GL11.glVertex3f( w,  0,  w);
        GL11.glVertex3f( w,  0, -w);
        GL11.glVertex3f(-w,  0, -w);

        GL11.glEnd();
    }

    /** Détermine la couleur ESP selon le type d'entité. */
    private Color getColorForEntity(Entity entity) {
        if (entity instanceof EntityPlayer) return colorPlayer;
        if (entity instanceof EntityMob)    return colorEnemy;
        return colorNeutral;
    }

    // --- Getters / Setters pour configuration en jeu ---

    public boolean isEnabled()                    { return enabled; }
    public void    setEnabled(boolean enabled)    { this.enabled = enabled; }
    public float   getOutlineWidth()              { return outlineWidth; }
    public void    setOutlineWidth(float w)       { this.outlineWidth = w; }
    public void    setColorPlayer(Color c)        { colorPlayer  = c; }
    public void    setColorEnemy(Color c)         { colorEnemy   = c; }
    public void    setColorNeutral(Color c)       { colorNeutral = c; }
}
