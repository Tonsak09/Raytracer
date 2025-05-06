#include "TextureCapture.h"
#include <algorithm>

TextureCapture::TextureCapture(int width, int height)
{
	glGenTextures(1, &renderID);
	glBindTexture(GL_TEXTURE_2D, renderID);

	//CaptureFramebuffer(width, height);
}

unsigned char* TextureCapture::CaptureFramebuffer(int width, int height)
{
	unsigned char* pixels = new unsigned char[width * height * 4];
	glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels);

	//FlipImageVertically(pixels, width, height);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);

	return pixels;
}

void TextureCapture::FlipImageVertically(unsigned char* pixels, int width, int height)
{
	int rowSize = width * 4; // 4 for RGBA
	for (int y = 0; y < height / 2; ++y)
	{
		int top = y * rowSize;
		int bottom = (height - 1 - y) * rowSize;
		for (int x = 0; x < rowSize; ++x)
		{
			std::swap(pixels[top + x], pixels[bottom + x]);
		}
	}
}