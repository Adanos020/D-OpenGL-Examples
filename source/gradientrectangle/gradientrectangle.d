module gradientrectangle;

import std.stdio,
       std.math;
import core.time;

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
    GLuint vao;
    GLuint vbo;
    GLuint ebo;

    GLuint vertexShader;
    GLuint fragmentShader;

    GLuint shaderProgram;

    GLuint posAttrib;
    GLuint colAttrib;

    void draw()
    {
        glDrawElements(PRIMITIVE_TYPE, 6, GL_UNSIGNED_INT, cast(void*) 0);
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

private struct Rectangle
{
    mixin GL_Drawable!GL_TRIANGLES;

    float[] vertices = [
       -0.5f,  0.5f, 1.0f, 0.0f, 0.0f, // Top-left
        0.5f,  0.5f, 0.0f, 1.0f, 0.0f, // Top-right
        0.5f, -0.5f, 0.0f, 0.0f, 1.0f, // Bottom-right
       -0.5f, -0.5f, 1.0f, 1.0f, 1.0f  // Bottom-left
    ];

    GLuint[] elements = [
        0, 1, 2,
        2, 3, 0
    ];

    GLint uniColor;

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

        load("source/gradientrectangle/vertexShader.vert", vertexSRC);
        load("source/gradientrectangle/fragmentShader.frag", fragmentSRC);
    }
}

///
struct GradientRectangleApp
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

    Rectangle rectangle;

    void initWindow()
    {
        DerelictGLFW3.load();
        glfwInit();

        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);

        glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);

        window = glfwCreateWindow(800, 600, "Gradient Rectangle!", null, null);

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
        glGenVertexArrays(1, &rectangle.vao);
        glBindVertexArray(rectangle.vao);

        // creating a vertex buffer object
        glGenBuffers(1, &rectangle.vbo);
        glBindBuffer(GL_ARRAY_BUFFER, rectangle.vbo);
        glBufferData(GL_ARRAY_BUFFER, rectangle.vertices.length / 3 * rectangle.vertices.sizeof,
                     rectangle.vertices.ptr, GL_STATIC_DRAW);

        // creating an element buffer object
        glGenBuffers(1, &rectangle.ebo);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, rectangle.ebo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, rectangle.elements.length * rectangle.vertices.sizeof,
                     rectangle.elements.ptr, GL_STATIC_DRAW);

        // compiling the shaders
        rectangle.loadShaders();

        const(GLchar)* vert = rectangle.vertexSRC.ptr;
        const(GLchar)* frag = rectangle.fragmentSRC.ptr;

        rectangle.vertexShader = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(rectangle.vertexShader, 1, &vert, null);
        glCompileShader(rectangle.vertexShader);

        write("Vertex shader: ");
        shaderCompilationLog(rectangle.vertexShader);

        rectangle.fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(rectangle.fragmentShader, 1, &frag, null);
        glCompileShader(rectangle.fragmentShader);

        write("Fragment shader: ");
        shaderCompilationLog(rectangle.fragmentShader);

        // creating the shader program
        rectangle.shaderProgram = glCreateProgram();
        glAttachShader(rectangle.shaderProgram, rectangle.vertexShader);
        glAttachShader(rectangle.shaderProgram, rectangle.fragmentShader);

        glLinkProgram(rectangle.shaderProgram);
        glUseProgram(rectangle.shaderProgram);

        // linking the vertex data and attributes
        rectangle.posAttrib = glGetAttribLocation(rectangle.shaderProgram, "position");
        glEnableVertexAttribArray(rectangle.posAttrib);
        glVertexAttribPointer(rectangle.posAttrib, 2, GL_FLOAT, GL_FALSE,
                              5 * float.sizeof, cast(void*)(0));

        rectangle.colAttrib = glGetAttribLocation(rectangle.shaderProgram, "color");
        glEnableVertexAttribArray(rectangle.colAttrib);
        glVertexAttribPointer(rectangle.colAttrib, 3, GL_FLOAT, GL_FALSE,
                              5 * float.sizeof, cast(void*)(2 * float.sizeof));
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

        rectangle.draw();

        glfwSwapBuffers(window);
    }
}
