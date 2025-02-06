#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include <iostream>

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

    std::string vertexShader =
        "#version 330 core\n"
        "\n"
        "layout (location = 0) in vec4 position;\n"
        "out vec2 uv;\n"
        "\n"

        "void main()\n"
        "{\n"
        "   gl_Position = vec4(position.xy, 0.0, 1.0);\n"
        "   uv = position.zw;\n"
        "}\n";

    std::string fragmentShader =
        "#version 330 core\n"
        "\n"
        "layout (location = 0) out vec4 color;\n"
        "in vec2 uv;\n"
        "\n"
        "void main()\n"
        "{\n"
        "   color = vec4(uv, 0.0, 1.0); \n"
        "}\n";


    unsigned int shader = CreateShader(vertexShader, fragmentShader);
    glUseProgram(shader);

    /* Loop until the user closes the window */
    while (!glfwWindowShouldClose(window))
    {
        /* Render here */
        glClear(GL_COLOR_BUFFER_BIT);

        glDrawArrays(GL_TRIANGLES, 0, 3);

        /* Swap front and back buffers */
        glfwSwapBuffers(window);

        /* Poll for and process events */
        glfwPollEvents();
    }
    
    glDeleteProgram(shader);

    glfwTerminate();
    return 0;
}