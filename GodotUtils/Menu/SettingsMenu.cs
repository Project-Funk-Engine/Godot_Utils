using Godot;
using System;
using System.Linq;

public partial class SettingsMenu : CanvasLayer, SettingsMenu.IFocusableMenu
{
#region Focusable Menu
    public interface IFocusableMenu
    {
        IFocusableMenu Prev { get; set; }
        const ProcessModeEnum DefaultProcessMode = ProcessModeEnum.Always;
        void OpenMenu(IFocusableMenu parentMenu);
        void PauseFocus();
        void ResumeFocus();
        void ReturnToPrev();
    }
    
    public IFocusableMenu Prev { get; set; }
    private Control _lastFocus;
    const ProcessModeEnum DefaultProcessMode = ProcessModeEnum.Always;

    public void ResumeFocus()
    {
        ProcessMode = DefaultProcessMode;
        _lastFocus.GrabFocus();
    }

    public void PauseFocus()
    {
        _lastFocus = GetViewport().GuiGetFocusOwner();
        ProcessMode = ProcessModeEnum.Disabled;
    }

    public void OpenMenu(IFocusableMenu prev)
    {
        Prev = prev;
        Prev.PauseFocus();
        //Default grab focus
    }

    public void ReturnToPrev()
    {
        if (Prev == null) return;
        Prev.ResumeFocus();
        QueueFree();
    }
#endregion

#region Settings
    [Export] HSlider _volume;
    [Export] OptionButton _localeSelect;

    private void VolumeChanged(double volume)
    {
        AudioServer.SetBusVolumeDb(AudioServer.GetBusIndex("Master"), (float)Mathf.LinearToDb(volume));
    }

    private void SetLocales()
    {
        int idx = 0;
        bool setLocales = false;
        foreach (String s in TranslationServer.GetLoadedLocales())
        {
            _localeSelect.AddItem(s);
            if (s == "en" && !setLocales)
                _localeSelect.Selected = idx;
            if (s == TranslationServer.GetLocale())
            {
                _localeSelect.Selected = idx;
                setLocales = true;
            }
            idx++;
        }
    }

    private void ChangeLocale(long idx)
    {
        TranslationServer.SetLocale(TranslationServer.GetLoadedLocales()[(int)idx]);
    }

#endregion

    public override void _EnterTree()
    {
        _volume.Value = Mathf.DbToLinear(AudioServer.GetBusVolumeDb(AudioServer.GetBusIndex("Master")));
        _volume.ValueChanged += VolumeChanged;
        SetLocales();
        _localeSelect.ItemSelected += ChangeLocale;
    }
}
