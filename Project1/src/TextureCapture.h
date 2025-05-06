#pragma once

#include <GL/glew.h>

struct TextureCapture
{
public:
	TextureCapture(int width, int height);
	void FlipImageVertically(unsigned char* pixels, int width, int height);
	GLuint renderID;

	unsigned char* CaptureFramebuffer(int width, int height);
};