#pragma once
#include <cstdint>
#include <stdio.h>
#include <string.h>
#include <opencv2/core/base.hpp>
#include <opencv2/core/mat.hpp>

class ImageData
{
public:
	int32_t Width;
	int32_t Height;
	int32_t NumberOfChannels;
	int32_t BytesLength;
	uint8_t * Bytes;

	ImageData(cv::Mat mat);

	ImageData(int32_t width, 
			  int32_t height, 
			  int32_t numberOfChannels, 
			  uint8_t * bytes, 
			  int32_t bytesLength);

	cv::Mat toMat();
};
