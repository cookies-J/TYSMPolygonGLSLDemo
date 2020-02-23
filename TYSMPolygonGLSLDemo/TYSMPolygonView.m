//
//  TYSMPolygonView.m
//  TYSMOpenGLES
//
//  Created by jele lam on 2019/11/23.
//  Copyright © 2019 Cookies. All rights reserved.
//

#import "TYSMPolygonView.h"
#import <OpenGLES/ES2/gl.h>

typedef struct{
    GLfloat Position[2]; // {x,y,z};
}VFVertex;
static const VFVertex vertices[4*2] = {
    {{0.5f, -0.5f}},
    {{-0.5f, -0.5f}},
    {{-0.5f, 0.5f}},
    {{0.5f, 0.5f}},
//    {{1.f, -1.f}},
//    {{-1.f, -1.f}},
//    {{-1.f, 1.f}},
//    {{1.f, 1.f}},
};

@interface TYSMPolygonView ()
@property (nonatomic, strong) EAGLContext *glContext;
@end

@implementation TYSMPolygonView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        CAEAGLLayer *glLayer = (CAEAGLLayer *)self.layer;
        glLayer.drawableProperties = @{
            kEAGLDrawablePropertyRetainedBacking    : @(YES),
            kEAGLDrawablePropertyColorFormat        : kEAGLColorFormatRGBA8
            
        };
        
        glLayer.contentsScale = [UIScreen mainScreen].scale;
        glLayer.opaque = YES;
        
        [self configureEAGLContext];
        
        // 创建帧缓冲区
        [self createFrameBuffer];
        // 创建渲染缓冲区
        GLuint renderBuffer =[self createRenderBuffer];
        // 将渲染缓冲区附加到帧缓冲
        [self attachRenderBuffer:renderBuffer];
        // 绑定一个 layer ，用于呈现内容。就类似一块画板，渲染的内容都呈现这块画板里。
        [self bindDrawableObjectToRenderBuffer];
        // 擦板子
        [self clearColor];
        // 创建顶点缓冲区
        GLuint verticBuffer =[self createVerticBuffer];
        // 绑定顶点数据到顶点缓冲区
        [self bindVertxDataWithVertxBuffer:verticBuffer];
        
        // 这里开始就类似有些编译原理的
        
        // 创建顶点 shader
        GLuint verticShader = [self createShaderWithType:GL_VERTEX_SHADER];
        // 编译顶点 shader
        [self complieVertexShaderWithShader:verticShader type:GL_VERTEX_SHADER];
        // 创建片元 shader
        GLuint fragmentShader = [self createShaderWithType:GL_FRAGMENT_SHADER];
        // 编译片元 shader
        [self complieVertexShaderWithShader:fragmentShader type:GL_FRAGMENT_SHADER];
        // 创建着色器 shader
        GLuint shaderProgram = [self createShaderProgram];
        // 把顶点 shader、片元 shader 装载 shader 程序
        [self attchShaderToProgram:shaderProgram vertextShader:verticShader fragmentShader:fragmentShader];
        // 链接 shader 程序
        [self linkProgramWithProgram:shaderProgram];
        
        // 先清理一遍 渲染 缓冲区，避免杂质
        [self clearRenderBuffer];
        // 设置渲染的，目前只是一张画板，需要在这块画板的哪个区域呈现内容
        [self setRenderViewPort];
        // 安装 shader ，作为渲染对象的一部分
        [self userShaderWithProgram:shaderProgram];
        // 关联顶点数据的数组，这一步将决定渲染内容
        [self attachTriangleVertexArrays];
        // 渲染到画板上
        [self drawTriangle];
        // 并且显示出来
        [self render];
        
        
        
        
    }
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)configureEAGLContext {
    self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.glContext];
}

/** 创建 frameBuffer 并且绑定 */
- (GLuint)createFrameBuffer {
    GLuint frameBuffer;
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    return frameBuffer;
}

- (GLuint)createRenderBuffer {
    GLuint renderBuffer;
    
    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    
    return renderBuffer;
}

- (void)attachRenderBuffer:(GLuint)renderBuffer {
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
}

- (void)bindDrawableObjectToRenderBuffer {
    [self.glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
}

- (void)clearColor {
    glClearColor(0.3f, 0.4f, 0.5f, 1.f);
}

#pragma mark - 创建 顶点缓冲区
#define VertexBufferMemoryBlock    (1)
- (GLuint)createVerticBuffer {
    GLuint vertexBuffer;
    
    glGenBuffers(VertexBufferMemoryBlock, &vertexBuffer);
    
    return vertexBuffer;
}

- (void)bindVertxDataWithVertxBuffer:(GLuint)vertxBuffer {
    glBindBuffer(GL_ARRAY_BUFFER, vertxBuffer);
    
    // 告诉程序怎么去使用这些顶点数据
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
}

#pragma mark - 创建 顶点着色器、片段着色器

- (void)complieVertexShaderWithShader:(GLuint)shader type:(GLenum)type {
    // 编译着色器代码
    
    glCompileShader(shader);
    GLint complieStatus;
    
    // 获取着色器对象的相关信息
    glGetShaderiv(shader, GL_COMPILE_STATUS, &complieStatus);
    
    if (complieStatus == GL_FALSE) {
        GLint infoLength;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLength);
        if (infoLength > 0) {
            GLchar *infoLog = malloc(sizeof(GLchar) * infoLength);
            // 获取着色器的打印消息
            glGetShaderInfoLog(shader, infoLength, NULL, infoLog);
            NSLog(@"%s -> %s", (type == GL_VERTEX_SHADER) ? "vertex shader" : "fragment shader", infoLog);
            free(infoLog);
        }
    }
}

- (GLuint)createShaderWithType:(GLenum)type {
    // 创建一个着色器对象
    GLuint shader = glCreateShader(type);
    
    const GLchar *code = (type == GL_VERTEX_SHADER)? [[self class] vertexShaderCode] : [[self class] fragmentShaderCode];
    // 关联顶点、片元着色器的代码
    glShaderSource(shader, 1, &code, NULL);
    
    return shader;
}

#pragma mark - 创建 着色器 程序
- (GLuint)createShaderProgram {
    return glCreateProgram();
}

#pragma mark - 装载
- (void)attchShaderToProgram:(GLuint)program vertextShader:(GLuint)vertexShader fragmentShader:(GLuint)fragmentShader {
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
}

#pragma mark - 链接 着色器程序
- (void)linkProgramWithProgram:(GLint)program {
    glLinkProgram(program);
    GLint linkstatus;
    glGetProgramiv(program, GL_LINK_STATUS, &linkstatus);
    
    if (linkstatus == GL_FALSE) {
        GLint infoLength;
            glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLength);
            if (infoLength > 0) {
                GLchar *infoLog = malloc(sizeof(GLchar) * infoLength);
                glGetProgramInfoLog(program, infoLength, NULL, infoLog);
                NSLog(@"%s", infoLog);
                free(infoLog);
            }
        }
    
}

#pragma mark - 绘制
#pragma mark - 清空旧的渲染缓存
- (void)clearRenderBuffer {
    glClear(GL_COLOR_BUFFER_BIT);
}

#pragma mark - 设置渲染窗口
- (void)setRenderViewPort {
    GLint renderBufferWidth, renderBufferHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &renderBufferWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &renderBufferHeight);
    glViewport(0,0,
               renderBufferWidth,
               renderBufferHeight);
}

#pragma mark - 使用 着色器程序

- (void)userShaderWithProgram:(GLuint)program {
    glUseProgram(program);
}

+ (GLchar *)fragmentShaderCode {
    return  "#version 100 \n"
            "void main(void) { \n"
                "gl_FragColor = vec4(0.5, 0.5, 0.5, 0); \n"
            "}";
}

+ (GLchar *)vertexShaderCode {
    return  "#version 100 \n"
            "attribute vec4 v_Position; \n"
            "void main(void) { \n"
                "gl_Position = v_Position;\n"
            "}";
}


#pragma mark - 关联数据
    
#define VertexAttributePosition     (0)
#define StrideCloser                (0)
- (void)attachTriangleVertexArrays {
    glEnableVertexAttribArray(VertexAttributePosition);
    
    glVertexAttribPointer(VertexAttributePosition, 3, GL_FLOAT, GL_FALSE, sizeof(VFVertex), (const GLvoid *) offsetof(VFVertex, Position));
}

#define PositionStartIndex          (0)
#define DrawIndicesCount            (4)

- (void)drawTriangle {
    glDrawArrays(GL_TRIANGLE_FAN, PositionStartIndex, DrawIndicesCount);
}

#pragma mark - 渲染

- (void)render {
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - Layer

+ (Class)layerClass {
    return [CAEAGLLayer class];
}


@end
