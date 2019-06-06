/*
 ------------------------------------------------------------------
 
 Python Plugin
 Copyright (C) 2016 FP Battaglia
 
 based on
 Open Ephys GUI
 Copyright (C) 2013, 2015 Open Ephys
 
 ------------------------------------------------------------------
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 */
/*
  ==============================================================================

    PythonEditor.h
    Created: 13 Jun 2014 4:21:01pm
    Author:  fpbatta

  ==============================================================================
*/

#ifndef __PYTHONEDITOR_H
#define __PYTHONEDITOR_H

#include <EditorHeaders.h>

class PythonPlugin;
class PythonParameterButtonInterface;

class PythonEditor : public GenericEditor

{
public:
    PythonEditor(GenericProcessor* parentNode, bool useDefaultParameterEditors);
    virtual ~PythonEditor();

    void buttonEvent(Button* button);

    void channelChanged(int chan, bool newState) override;

    void setFile(String file);

    void saveCustomParameters(XmlElement*);

    void loadCustomParameters(XmlElement*);

    Component *addToggleButton(String, bool);
    
    Component *addComboBox(String, int, int*);
    
    Component *addSlider(String, float, float, float);
    
    
    
private:
    

    ScopedPointer<UtilityButton> fileButton;
    ScopedPointer<Label> fileNameLabel;

    OwnedArray<Component> parameterInterfaces;
    PythonPlugin* pythonPlugin;

    File lastFilePath;
    Font font;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(PythonEditor);

};


class PythonParameterButtonInterface : public Component,  public Button::Listener
{
public:
    PythonParameterButtonInterface(String paramName_, int defaultVal, PythonPlugin *plugin_);
    ~PythonParameterButtonInterface();
    void paint(Graphics& g);
    void buttonClicked(Button* button);
    void setToggleStateFromValue(int value);
    
private:
    String paramName;
    bool isEnabled;
    PythonPlugin *plugin;
    ScopedPointer<ToggleButton> theButton;
    Font font;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(PythonParameterButtonInterface);
    
};

class PythonParameterComboBoxInterface : public Component,  public ComboBox::Listener
{
public:
    PythonParameterComboBoxInterface(String paramName_, int nEntries_, int *entries_, PythonPlugin *plugin_);
    ~PythonParameterComboBoxInterface();
    void paint(Graphics& g);
    void comboBoxChanged(ComboBox* comboBox);
    void setEntryFromValue(int value);
    
private:
    String paramName;
    int nEntries;
    int *entries;
    bool lastState;
    bool isEnabled;
    PythonPlugin *plugin;
    ScopedPointer<ComboBox> theComboBox;
    Font font;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(PythonParameterComboBoxInterface);
    
};

class PythonParameterSliderInterface : public Component,  public Slider::Listener
{
public:
    PythonParameterSliderInterface(String paramName_, double rangeMin, double rangeMax, double startValue, PythonPlugin *plugin_);
    ~PythonParameterSliderInterface();
    void paint(Graphics& g);
    void sliderValueChanged(Slider* slider);
    void setSliderFromValue(float value);
    
private:
    String paramName;
    bool isEnabled;
    PythonPlugin *plugin;
    ScopedPointer<Slider> theSlider;
    ScopedPointer<Label> titleLabel;
    Font font;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(PythonParameterSliderInterface);
};



#endif  // __PYTHONEDITOR_H
