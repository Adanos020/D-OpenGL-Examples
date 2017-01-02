module texturedrect;

import std.stdio;

import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;
import imageformats;

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
struct Shader
{
private:
    GLuint vertexShader;
    GLuint fragmentShader;

    GLuint shaderProgram;

    GLchar[] vertexSRC_;
    GLchar[] fragmentSRC_;

public:
    @property
    {
        ///
        GLuint program()
        {
            return shaderProgram;
        }
    }

    ///
    void loadVertex(in string path)
    {
        File file;
        file.open(path, "r");
        if (file.error)
        {
            throw new Exception("Failed to load shader from file `" ~ path ~ "`");
        }

        write("Loading shader file `" ~ path ~ "`... ");
        while (!file.eof)
        {
            vertexSRC_ ~= file.readln;
        }
        writeln("Done.");
    }

    ///
    void loadFragment(in string path)
    {
        File file;
        file.open(path, "r");
        if (file.error)
        {
            throw new Exception("Failed to load shader from file `" ~ path ~ "`");
        }

        write("Loading shader file `" ~ path ~ "`... ");
        while (!file.eof)
        {
            fragmentSRC_ ~= file.readln;
        }
        writeln("Done.");
    }

    ///
    void compile()
    {
        const(GLchar)* vert = vertexSRC_.ptr;
        const(GLchar)* frag = fragmentSRC_.ptr;

        vertexShader = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(vertexShader, 1, &vert, null);
        glCompileShader(vertexShader);
        shaderCompilationLog(vertexShader);

        fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(fragmentShader, 1, &frag, null);
        glCompileShader(fragmentShader);
        shaderCompilationLog(fragmentShader);
    }

    ///
    void create()
    {
        shaderProgram = glCreateProgram();
        glAttachShader(shaderProgram, vertexShader);
        glAttachShader(shaderProgram, fragmentShader);
        glBindFragDataLocation(shaderProgram, 0, "outColor");
        glLinkProgram(shaderProgram);
        glUseProgram(shaderProgram);
    }
}

///
struct Sprite
{
private:
    Shader shader_;

    Texture* texture_;

    GLfloat[] vertices_ =
    [
    //| Position   | Color         | Texcoords |
        -0.38,  0.5 , 1.0, 1.0, 1.0 , 0.0, 0.0, // Top-left
         0.38,  0.5 , 1.0, 1.0, 1.0 , 1.0, 0.0, // Top-right
         0.38, -0.5 , 1.0, 1.0, 1.0 , 1.0, 1.0, // Bottom-right
        -0.38, -0.5 , 1.0, 1.0, 1.0 , 0.0, 1.0  // Bottom-left
    ];

    GLuint[] elements_ =
    [
        0, 1, 2,
        2, 3, 0
    ];

public:
    ///
    void opCall()
    {
        GLuint vao;
        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);

        GLuint vbo;
        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, vertices_.length * vertices_.sizeof,
                     vertices_.ptr, GL_STATIC_DRAW);

        GLuint ebo;
        glGenBuffers(1, &ebo);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, elements_.length * elements_.sizeof,
                     elements_.ptr, GL_STATIC_DRAW);

        shader_.loadVertex("source/texturedrect/vertexShader.vert");
        shader_.loadFragment("source/texturedrect/fragmentShader.vert");
        shader_.compile();
        shader_.create();

        GLuint posAttrib = glGetAttribLocation(shader_.program, "position");
        glEnableVertexAttribArray(posAttrib);
        glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE,
                              7 * float.sizeof, cast(void*)(0));

        GLuint colAttrib = glGetAttribLocation(shader_.program, "color");
        glEnableVertexAttribArray(colAttrib);
        glVertexAttribPointer(colAttrib, 3, GL_FLOAT, GL_FALSE,
                              7 * float.sizeof, cast(void*)(2 * float.sizeof));

        GLuint texAttrib = glGetAttribLocation(shader_.program, "texcoord");
        glEnableVertexAttribArray(texAttrib);
        glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE,
                              7 * float.sizeof, cast(void*)(5 * float.sizeof));
    }

    @property
    {
        ///
        void texture(Texture* texture)
        {
            texture_ = texture;
        }

        ///
        Texture* texture()
        {
            return texture_;
        }

        ///
        ref Shader shader()
        {
            return shader_;
        }
    }

    ///
    void draw()
    {
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, cast(void*) 0);
    }
}

///
struct Texture
{
private:
    IFImage image;

public:
    ///
    this(string path)
    {
        GLuint tex;
        glGenTextures(1, &tex);
        glBindTexture(GL_TEXTURE_2D, tex);

        image = read_png(path, ColFmt.RGB);

        glTexImage2D
        (
            GL_TEXTURE_2D,    // target
            0,                // level of detail
            GL_RGB,           // format of pixels stored on the graphics card
            image.w,          // width
            image.h,          // height
            0,                // ???
            GL_RGB,           // format of pixels loaded
            GL_UNSIGNED_BYTE, // ↑↑↑
            image.pixels.ptr  // the pixels
        );

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

        glGenerateMipmap(GL_TEXTURE_2D);
    }
}

///
struct TexturedRectApp
{
private:
    GLFWwindow* window;

    Sprite sprite;
    Texture texture;

    void initWindow()
    {
        DerelictGLFW3.load();
        glfwInit();

        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
        glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);

        window = glfwCreateWindow(800, 600, "Textured Rectangle!", null, null);

        glfwMakeContextCurrent(window);
    }

    void initOpenGL()
    {
        DerelictGL3.load();
        DerelictGL3.reload();
    }

    void initRender()
    {
        sprite();

        texture = Texture("assets/bricks.png");
        sprite.texture = &texture;
    }

    void mainLoop()
    {
        while (!glfwWindowShouldClose(window))
        {
            glClearColor(0.0, 0.0, 0.0, 1.0);
            glClear(GL_COLOR_BUFFER_BIT);

            sprite.draw();

            glfwSwapBuffers(window);

            glfwPollEvents();
        }
    }

public:
    ///
    void run()
    {
        initWindow();
        initOpenGL();
        initRender();
        mainLoop();
    }
}
