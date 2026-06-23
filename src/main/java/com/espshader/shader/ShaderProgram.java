package com.espshader.shader;

import com.espshader.ESPMod;
import net.minecraft.client.Minecraft;
import net.minecraft.util.ResourceLocation;
import org.lwjgl.opengl.ARBFragmentShader;
import org.lwjgl.opengl.ARBShaderObjects;
import org.lwjgl.opengl.ARBVertexShader;
import org.lwjgl.opengl.GL11;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

/**
 * Charge, compile et lie des programmes GLSL (vertex + fragment shader).
 * Utilise les extensions ARB pour compatibilité avec OpenGL 2.x (1.8.9).
 */
public class ShaderProgram {

    private int programId = 0;
    private int vertId    = 0;
    private int fragId    = 0;

    private final ResourceLocation vertLocation;
    private final ResourceLocation fragLocation;

    public ShaderProgram(String domain, String vertPath, String fragPath) {
        this.vertLocation = new ResourceLocation(domain, vertPath);
        this.fragLocation = new ResourceLocation(domain, fragPath);
    }

    /** Charge, compile et lie le programme. Retourne true si succès. */
    public boolean load() {
        try {
            String vertSrc = readResource(vertLocation);
            String fragSrc = readResource(fragLocation);

            vertId = compileShader(ARBVertexShader.GL_VERTEX_SHADER_ARB, vertSrc);
            fragId = compileShader(ARBFragmentShader.GL_FRAGMENT_SHADER_ARB, fragSrc);

            programId = ARBShaderObjects.glCreateProgramObjectARB();
            ARBShaderObjects.glAttachObjectARB(programId, vertId);
            ARBShaderObjects.glAttachObjectARB(programId, fragId);
            ARBShaderObjects.glLinkProgramARB(programId);
            ARBShaderObjects.glValidateProgramARB(programId);

            ESPMod.LOGGER.info("Shader ESP chargé avec succès (programId={})", programId);
            return true;
        } catch (Exception e) {
            ESPMod.LOGGER.error("Erreur chargement shader ESP", e);
            return false;
        }
    }

    private int compileShader(int type, String source) {
        int shaderId = ARBShaderObjects.glCreateShaderObjectARB(type);
        ARBShaderObjects.glShaderSourceARB(shaderId, source);
        ARBShaderObjects.glCompileShaderARB(shaderId);

        String log = ARBShaderObjects.glGetInfoLogARB(shaderId, 512);
        if (log != null && !log.trim().isEmpty()) {
            ESPMod.LOGGER.warn("Shader compile log: {}", log);
        }
        return shaderId;
    }

    private String readResource(ResourceLocation loc) throws Exception {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                Minecraft.getMinecraft().getResourceManager()
                         .getResource(loc).getInputStream(), StandardCharsets.UTF_8))) {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line).append('\n');
            }
            return sb.toString();
        }
    }

    /** Active ce programme shader. */
    public void bind() {
        if (programId != 0) ARBShaderObjects.glUseProgramObjectARB(programId);
    }

    /** Désactive les shaders (retour au pipeline fixe). */
    public static void unbind() {
        ARBShaderObjects.glUseProgramObjectARB(0);
    }

    /** Envoie un uniforme vec4 au shader. */
    public void setUniform4f(String name, float r, float g, float b, float a) {
        int loc = ARBShaderObjects.glGetUniformLocationARB(programId, name);
        if (loc != -1) ARBShaderObjects.glUniform4fARB(loc, r, g, b, a);
    }

    /** Envoie un uniforme float au shader. */
    public void setUniform1f(String name, float value) {
        int loc = ARBShaderObjects.glGetUniformLocationARB(programId, name);
        if (loc != -1) ARBShaderObjects.glUniform1fARB(loc, value);
    }

    /** Envoie un uniforme boolean (int 0/1) au shader. */
    public void setUniform1b(String name, boolean value) {
        int loc = ARBShaderObjects.glGetUniformLocationARB(programId, name);
        if (loc != -1) ARBShaderObjects.glUniform1iARB(loc, value ? 1 : 0);
    }

    public boolean isLoaded() {
        return programId != 0;
    }

    public void delete() {
        if (vertId    != 0) ARBShaderObjects.glDeleteObjectARB(vertId);
        if (fragId    != 0) ARBShaderObjects.glDeleteObjectARB(fragId);
        if (programId != 0) ARBShaderObjects.glDeleteObjectARB(programId);
        programId = vertId = fragId = 0;
    }
}
