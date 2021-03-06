module hellotriangle;

import std.stdio;

import derelict.opengl3.gl3,
       derelict.glfw3.glfw3;

///
void shaderCompilationLog(GLuint shader)
{
    GLint status;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);

    char[512] buffer;
    glGetShaderInfoLog(shader, 512, null, buffer.ptr);

    //writeln(buffer);
    writeln((status == GL_TRUE) ? "shader compilation succeeded."
                                : "shader compilation failed.");
}

///
mixin template GL_Drawable(uint PRIMITIVE_TYPE)
{
    GLuint vertexShader;
    GLuint fragmentShader;

    GLuint shaderProgram;

    GLuint posAttrib;

    void draw()
    {
        glDrawArrays(PRIMITIVE_TYPE, 0, 3);
    }

    version(none) // this constructor doesn't need to be compiled
    ~this()       // at this moment since it causes segmentation
    {             // faults
        glDeleteProgram(shaderProgram);
        glDeleteShader(vertexShader);
        glDeleteShader(fragmentShader);

        glDeleteBuffers(1, &vbo);

        glDeleteVertexArrays(1, &vao);
    }
}

private struct Triangle
{
    mixin GL_Drawable!GL_TRIANGLES;

    float[] vertices = [
         0.0,  0.5, // top
         0.5, -0.5, // bottom right
        -0.5, -0.5  // bottom left
    ];

// shader sources

    GLchar[] vertexSRC;
    GLchar[] fragmentSRC;

    void loadShaders()
    {
        void load(in string name, ref GLchar[] shader)
        {
            File file;
            file.open(name, "r");
            if (file.error)
            {
                throw new Exception("Failed to load shader from file `" ~ name ~ "`");
            }

            write("Loading shader file `" ~ name ~ "`... ");
            while (!file.eof)
            {
                shader ~= file.readln;
            }
            writeln("Done.");
        }

        load("source/hellotriangle/vertexShader.vert", vertexSRC);
        load("source/hellotriangle/fragmentShader.frag", fragmentSRC);
    }
}

///
struct HelloTriangleApp
{
public:
///
    void run()
    {
        initWindow();
        initOpenGL();
        initRender();
        mainLoop();
    }

    ~this()
    {
        DerelictGLFW3.unload();
        DerelictGL3.unload();
    }

private:
    GLFWwindow* window;

    Triangle triangle;

    void initWindow()
    {
        DerelictGLFW3.load();
        glfwInit();

        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);

        glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);

        window = glfwCreateWindow(800, 600, "Hello Triangle!", null, null);

        glfwMakeContextCurrent(window);
    }

    void initOpenGL()
    {
        DerelictGL3.load();
        DerelictGL3.reload(); // load the new OpenGL functions (GLEW)
    }

    void initRender()
    {
        // creating a vertex array object
        GLuint vao;
        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);

        // creating a vertex buffer object
        GLuint vbo;
        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, triangle.vertices.length / 3 * triangle.vertices.sizeof,
                     triangle.vertices.ptr, GL_STATIC_DRAW);

        // compiling the shaders
        triangle.loadShaders();

        const(GLchar)* vert = triangle.vertexSRC.ptr;
        const(GLchar)* frag = triangle.fragmentSRC.ptr;

        triangle.vertexShader = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(triangle.vertexShader, 1, &vert, null);
        glCompileShader(triangle.vertexShader);

        write("Vertex shader: ");
        shaderCompilationLog(triangle.vertexShader);

        triangle.fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(triangle.fragmentShader, 1, &frag, null);
        glCompileShader(triangle.fragmentShader);

        write("Fragment shader: ");
        shaderCompilationLog(triangle.fragmentShader);

        // creating the shader program
        triangle.shaderProgram = glCreateProgram();
        glAttachShader(triangle.shaderProgram, triangle.vertexShader);
        glAttachShader(triangle.shaderProgram, triangle.fragmentShader);

        glLinkProgram(triangle.shaderProgram);
        glUseProgram(triangle.shaderProgram);

        // linking the vertex data and attributes
        triangle.posAttrib = glGetAttribLocation(triangle.shaderProgram, "position");
        glEnableVertexAttribArray(triangle.posAttrib);
        glVertexAttribPointer(triangle.posAttrib, 2, GL_FLOAT, GL_FALSE, 0, null);
    }

    void mainLoop()
    {
        while (!glfwWindowShouldClose(window))
        {
            draw();
            glfwPollEvents();
        }

        glfwTerminate();
    }

    void draw()
    {
        glClearColor(0.0, 0.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);

        triangle.draw();

        glfwSwapBuffers(window);
    }
}
