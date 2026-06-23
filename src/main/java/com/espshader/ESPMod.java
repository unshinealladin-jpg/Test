package com.espshader;

import com.espshader.shader.ESPShaderRenderer;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.Mod.EventHandler;
import net.minecraftforge.fml.common.event.FMLInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPostInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

@Mod(
    modid     = ESPMod.MODID,
    name      = ESPMod.NAME,
    version   = ESPMod.VERSION,
    clientSideOnly = true
)
public class ESPMod {

    public static final String MODID   = "espshader";
    public static final String NAME    = "ESP Shader";
    public static final String VERSION = "1.0.0";

    public static final Logger LOGGER = LogManager.getLogger(NAME);

    // Instance singleton du mod
    @Mod.Instance(MODID)
    public static ESPMod instance;

    private ESPEventHandler eventHandler;

    @EventHandler
    public void preInit(FMLPreInitializationEvent event) {
        LOGGER.info("ESP Shader - PreInit");
    }

    @EventHandler
    public void init(FMLInitializationEvent event) {
        LOGGER.info("ESP Shader - Init");

        // Enregistrement du gestionnaire d'événements de rendu
        eventHandler = new ESPEventHandler();
        MinecraftForge.EVENT_BUS.register(eventHandler);
    }

    @EventHandler
    public void postInit(FMLPostInitializationEvent event) {
        LOGGER.info("ESP Shader - PostInit : chargement des shaders GLSL");

        // Initialisation du renderer de shaders (chargement des fichiers .vert/.frag)
        ESPShaderRenderer.getInstance().init();
    }
}
