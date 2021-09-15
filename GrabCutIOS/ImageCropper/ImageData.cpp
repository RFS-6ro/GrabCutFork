#include "ImageData.h"
#include "ImageCropperArgumentException.h"
#include "ImageCropperInternalException.h"

ImageData::ImageData(cv::Mat mat)
{
	try
	{
		Width = mat.cols;
		Height = mat.rows;
		NumberOfChannels = mat.channels();
		BytesLength = mat.total() * mat.elemSize();
		Bytes = new uint8_t[BytesLength];
		memcpy(Bytes, mat.data, BytesLength * sizeof(uint8_t));
	}
	catch (const std::exception&)
	{
		throw ImageCropperInternalException("Memory error");
	}
}

ImageData::ImageData(
	int32_t width, 
	int32_t height, 
	int32_t numberOfChannels, 
	uint8_t * bytes, 
	int32_t bytesLength)
{
	if (width < 0 || 
		height < 0 || 
		bytesLength < 0 ||
		numberOfChannels < 0 || 
		numberOfChannels > 4 ||
		bytes == nullptr)
	{
		throw ImageCropperArgumentException("Arguments are not valid");
	}

	try
	{
		Width = width;
		Height = height;
		NumberOfChannels = numberOfChannels;
		BytesLength = bytesLength;
		Bytes = new uint8_t[BytesLength];
		memcpy(Bytes, bytes, BytesLength * sizeof(uint8_t));
	}
	catch (const std::exception&)
	{
		throw ImageCropperInternalException("Memory error");
	}
}

cv::Mat ImageData::toMat()
{
	if (Bytes == nullptr)
	{
		throw ImageCropperArgumentException("Data is empty");
	}

	try
	{
		if (NumberOfChannels == 1)
		{
			return cv::Mat(Height, Width, CV_8UC1, Bytes);
		}

		if (NumberOfChannels == 3)
		{
			return cv::Mat(Height, Width, CV_8UC3, Bytes);
		}

		return cv::Mat();
	}
	catch (const std::exception&)
	{
		throw ImageCropperInternalException("Error with converting bytes to image");
	}
}
