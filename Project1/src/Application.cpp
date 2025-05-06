#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include <iostream>
#include <fstream>
#include <string>
#include <sstream>

#include "TextureCapture.h"

struct ShaderProgramSource
{
    std::string VertexSource;
    std::string FragmentSource; 
};

static ShaderProgramSource ParseShader(const std::string& filePath)
{
    std::ifstream stream(filePath);

    enum class ShaderType
    {
        NONE = -1, VERTEX = 0, FRAGMENT = 1
    };

    std::string line; 
    std::stringstream ss[2];
    ShaderType type = ShaderType::NONE;
    while (getline(stream, line))
    {
        if (line.find("#shader") != std::string::npos)
        {
            if (line.find("vertex") != std::string::npos)
            {
                // Set to vertex mode 
                type = ShaderType::VERTEX; 
            }
            else if (line.find("fragment") != std::string::npos)
            {
                // Set to fragment mode 
                type = ShaderType::FRAGMENT;
            }
        }
        else
        {
            ss[(int)type] << line << '\n';
        }
    }

    return { ss[0].str(), ss[1].str() };
}

static unsigned int CompileShader(const std::string& source, unsigned int type)
{
    unsigned int id = glCreateShader(type);
    const char* src = source.c_str();
    glShaderSource(id, 1, &src, nullptr);
    glCompileShader(id);

    int result;
    glGetShaderiv(id, GL_COMPILE_STATUS, &result);
    if (result == GL_FALSE)
    {
        int length;
        glGetShaderiv(id, GL_INFO_LOG_LENGTH, &length);
        char* message = (char*)alloca(length * sizeof(char));
        glGetShaderInfoLog(id, length, &length, message);

        std::cout << "Failed to compile shader!" << std::endl;
        std::cout << message << std::endl;
        glDeleteShader(id);
        return 0;
    }

    return id;
}

static unsigned int CreateShader(const std::string& vertexShader, const std::string& fragmentShader)
{
    unsigned int program = glCreateProgram();
    unsigned int vs = CompileShader(vertexShader, GL_VERTEX_SHADER);
    unsigned int fs = CompileShader(fragmentShader, GL_FRAGMENT_SHADER);

    glAttachShader(program, vs);
    glAttachShader(program, fs);
    glLinkProgram(program);
    glValidateProgram(program);

    glDeleteShader(vs);
    glDeleteShader(fs);

    return program;
}

void SetFloatToShader(GLuint shaderProgram, const std::string& uniformName, float value);

const int width = 640 * 2;
const int height = 480 * 2;

int main(void)
{
    GLFWwindow* window;

    /* Initialize the library */
    if (!glfwInit())
        return -1;


    /* Create a windowed mode window and its OpenGL context */
    window = glfwCreateWindow(width, height, "Hello World", NULL, NULL);
    if (!window)
    {
        glfwTerminate(); 
        return -1;
    }

    /* Make the window's context current */
    glfwMakeContextCurrent(window);
    

    // Must be done after the context is created  
    if (glewInit() != GLEW_OK)
    {
        return -1;
    }

    std::cout << glGetString(GL_VERSION) << std::endl;

    const int dataPerVert = 4;
    const int vertDataTotal = dataPerVert * 3;
    float positions[vertDataTotal] =
    {
        -1.0f,  1.0f, 0.0f, 0.0f,
         3.0f,  1.0f, 2.0f, 0.0f,
        -1.0f, -3.0f, 0.0f, 2.0f
    };

    // Initialize the buffer and bind it 
    unsigned int buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, vertDataTotal * sizeof(float), positions, GL_STATIC_DRAW);

    glVertexAttribPointer(0, dataPerVert, GL_FLOAT, GL_FALSE, dataPerVert * sizeof(float), 0);
    glEnableVertexAttribArray(0); 

    ShaderProgramSource source = ParseShader("./res/shaders/Basic.shader");
    std::cout << "VERTEX" << std::endl;
    std::cout << source.VertexSource << std::endl;
    std::cout << "FRAGMENT" << std::endl;
    std::cout << source.FragmentSource << std::endl;
  
    unsigned int shader = CreateShader(source.VertexSource, source.FragmentSource);
    glUseProgram(shader);

    /* Loop until the user closes the window */
    while (!glfwWindowShouldClose(window))
    {
        /* Render here */
        glClear(GL_COLOR_BUFFER_BIT);

        // Draw scene initial 
        SetFloatToShader(shader, "u_avgLuminance", -1.0f);
        glDrawArrays(GL_TRIANGLES, 0, 3);

        // Capture scene 
        glActiveTexture(GL_TEXTURE0);
        TextureCapture capture(width, height);
        unsigned char* textureCapture = capture.CaptureFramebuffer(width, height);

        // Compute average luminance 
        //const float maxLuminance = 100000.0f; 
        float totalLuminance = 0.0f; 
        for (uint32_t p = 0; p < width * height * 4; p += 4)
        {
            float readValue = static_cast<float>(textureCapture[p]) / 255.0f;
            float luminance = readValue;// *maxLuminance;

            totalLuminance += luminance;
        }

        float avgLuminance = totalLuminance / (width * height);


        // Draw with average luminance 
        SetFloatToShader(shader, "u_avgLuminance", avgLuminance);
        glDrawArrays(GL_TRIANGLES, 0, 3);

        delete[] textureCapture;

        /* Swap front and back buffers */
        glfwSwapBuffers(window);

        /* Poll for and process events */
        glfwPollEvents();
    }
    
    glDeleteProgram(shader);

    glfwTerminate();
    return 0;
}


void SetFloatToShader(GLuint shaderProgram, const std::string& uniformName, float value)
{
    GLint location = glGetUniformLocation(shaderProgram, uniformName.c_str());
    if (location != -1)
    {
        glUseProgram(shaderProgram);
        glUniform1f(location, value);
    }
    else
    {
        std::cerr << "Warning: uniform '" << uniformName << "' not found in shader.\n";
    }
}