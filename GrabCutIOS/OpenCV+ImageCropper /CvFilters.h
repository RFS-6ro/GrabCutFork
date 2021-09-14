#pragma once

//#include <opencv2/opencv.hpp>

class CvFilters
{
public:
    static cv::Mat makeTransparent(cv::Mat img);
	static void applyGrabCut(cv::Mat * img, cv::Rect rect, cv::Mat * mask = nullptr);
    static void cropContours(cv::Mat * img);
};

