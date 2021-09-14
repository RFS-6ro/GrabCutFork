#pragma once
#include <opencv2/opencv.hpp>
#include <algorithm>

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

public:
    ImageCropper();
    ImageCropper(cv::Mat sourceData);

    void setSourceImage(cv::Mat sourceData);

    void setMask(cv::Mat maskData);
	void setMask(int32_t * white, 
				 int32_t whiteLength,
				 int32_t * black,
				 int32_t blackLength);

    void setRectangle(int32_t x1, int32_t y1, int32_t x2, int32_t y2);
    void setRectangle(cv::Rect rect);
    cv::Mat f;
    cv::Mat getCroppedMat();
};
