
import java.text.SimpleDateFormat;
import java.sql.Date;

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author Aidan-WC
 */
public class Day 
{
    private Date date;
    
    public Day(Date date)
    {
        this.date = date;
    }
    
    public Day(String date)
    {
        String reformDate = date.substring(6, 10) + "-" + date.substring(3, 5) + "-" + date.substring(0, 2);
        this.date = Date.valueOf(reformDate);
    }
    
    public Date getDate()
    {
        return date;
    }
    public void setDate(Date date)
    {
        this.date = date;
    }
    
    public String getDateString()
    {
        String dateString = date.toString();
        String reformDateString = dateString.substring(8, 10) + "/" + dateString.substring(5, 7) + "/" + dateString.substring(0, 4);
        return reformDateString;
    }
}
