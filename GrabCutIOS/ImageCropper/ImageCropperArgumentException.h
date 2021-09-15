#pragma once
#include <string>

class ImageCropperArgumentException
{
private:
    std::string m_error;

public:
    ImageCropperArgumentException(std::string error) : m_error(error) { }

    const char* getError() { return m_error.c_str(); }
};

