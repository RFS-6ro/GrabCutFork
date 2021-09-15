#pragma once
#include <opencv2/opencv.hpp>
#include <opencv2/objdetect.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/highgui.hpp>
#include <algorithm>
#include "ImageData.h"

class ImageCropper
{
private:
	cv::Mat srcImg;
	cv::Mat mask;
	cv::Rect rect;

	cv::Mat bgdModel;
	cv::Mat fgdModel;

	int32_t pxlWidth;
	int32_t pxlHeight;
	//cv::Mat src, src_gray;
	//cv::Mat dst, detected_edges;
	//cv::Mat removeShadows(cv::Mat inputImage);
	//cv::Mat convertToGray(cv::Mat inputImage);
	//cv::Mat sobel(cv::Mat grayImage);
	//cv::Mat cannyThreshold(cv::Mat);
	//cv::Mat dilate(cv::Mat grayImage);
	//cv::Mat floodFill(cv::Mat grayImage);
	//cv::Mat interpolateContours(cv::Mat grayImage);
	//cv::Mat erode(cv::Mat grayImage);
	//cv::Mat findBiggestContour(cv::Mat gray, cv::Rect** boundingRectangle);
	//cv::Mat addAlphaChanel(cv::Mat currentImage, uint8_t* alphaChanel = nullptr, int rows = -1, int cols = -1);
	//cv::Mat addAlphaChanel(cv::Mat currentImage, cv::Mat alphaChanel);

public:
    ImageCropper();
    ImageCropper(cv::Mat sourceData);
	ImageCropper(ImageData sourceData);

	void setSourceImage(ImageData sourceData);
    void setSourceImage(cv::Mat sourceData);

    void setMask(cv::Mat maskData);
	void setMask(ImageData maskData);
	void setMask(int32_t * white, 
				 int32_t whiteLength,
				 int32_t * black,
				 int32_t blackLength);

    void setRectangle(int32_t x1, int32_t y1, int32_t x2, int32_t y2);
    void setRectangle(cv::Rect rect);
    
	ImageData getCroppedImage();
    cv::Mat getCroppedMat();
	//uint8_t* getCroppedImage(uint8_t* input, int rows, int cols);
	//uint8_t* cropImage(uint8_t* bytes, int x, int y, int width, int height);
	//uint8_t* removeThreshold(uint8_t* input, int rows, int cols, int threshold);
	//uint8_t* matToBytes(cv::Mat image);
	//cv::Mat bytesToMat(uint8_t* bytes, int rows, int cols);
};
