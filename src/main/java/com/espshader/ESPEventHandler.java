package com.espshader;

import com.espshader.shader.ESPShaderRenderer;
import net.minecraft.client.Minecraft;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityLivingBase;
import net.minecraftforge.client.event.RenderWorldLastEvent;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.gameevent.InputEvent;
import org.lwjgl.input.Keyboard;

import java.util.List;

/**
 * Gestionnaire d'événements Forge :
 *  - RenderWorldLastEvent  : déclenche le rendu ESP après le monde
 *  - InputEvent.KeyInputEvent : toggle ESP avec la touche HOME
 */
public class ESPEventHandler {

    // Touche de bascule ESP (HOME par défaut)
    private static final int TOGGLE_KEY = Keyboard.KEY_HOME;

    @SubscribeEvent
    public void onRenderWorldLast(RenderWorldLastEvent event) {
        Minecraft mc = Minecraft.getMinecraft();
        if (mc.theWorld == null || mc.thePlayer == null) return;

        double px = mc.getRenderManager().viewerPosX;
        double py = mc.getRenderManager().viewerPosY;
        double pz = mc.getRenderManager().viewerPosZ;

        // Parcours de toutes les entités vivantes chargées
        List<Entity> entities = mc.theWorld.loadedEntityList;
        for (Entity entity : entities) {
            if (!(entity instanceof EntityLivingBase)) continue;
            if (entity == mc.thePlayer)                continue;

            double rx = entity.lastTickPosX + (entity.posX - entity.lastTickPosX) * event.partialTicks - px;
            double ry = entity.lastTickPosY + (entity.posY - entity.lastTickPosY) * event.partialTicks - py;
            double rz = entity.lastTickPosZ + (entity.posZ - entity.lastTickPosZ) * event.partialTicks - pz;

            ESPShaderRenderer.getInstance().renderESP(entity, rx, ry, rz);
        }
    }

    @SubscribeEvent
    public void onKeyInput(InputEvent.KeyInputEvent event) {
        if (Keyboard.isKeyDown(TOGGLE_KEY)) {
            ESPShaderRenderer renderer = ESPShaderRenderer.getInstance();
            renderer.setEnabled(!renderer.isEnabled());

            String state = renderer.isEnabled() ? "ACTIVÉ" : "DÉSACTIVÉ";
            ESPMod.LOGGER.info("ESP Shader {}", state);

            // Affichage d'un message dans le chat du jeu
            Minecraft mc = Minecraft.getMinecraft();
            if (mc.thePlayer != null) {
                mc.thePlayer.addChatMessage(
                    new net.minecraft.util.ChatComponentText(
                        "§b[ESP Shader] §f" + state
                    )
                );
            }
        }
    }
}
