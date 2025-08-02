# Railway Deployment Troubleshooting

Your deployment is failing due to PORT variable issues. Here are the fixes and troubleshooting steps:

## 🔧 Quick Fixes Applied

### 1. Updated Procfile
```
web: gunicorn app:app --bind 0.0.0.0:${PORT:-8000} --workers 1
```

### 2. Created Startup Scripts
- `railway_start.py` - Python-based startup script
- `start.sh` - Bash-based startup script
- `debug_railway.py` - Debug information script

### 3. Updated Railway Configuration
- Fixed `railway.json` startup command
- Added environment variable handling

## 🚀 Deployment Steps

### Option 1: Use the Fixed Procfile (Recommended)
1. Commit and push the changes:
   ```bash
   git add .
   git commit -m "Fix Railway PORT variable issue"
   git push origin main
   ```

2. Railway will automatically redeploy

### Option 2: Manual Railway CLI Deployment
```bash
# Install Railway CLI if not already installed
curl -fsSL https://railway.app/install.sh | sh

# Login and deploy
railway login
railway up
```

### Option 3: Environment Variable Fix in Railway Dashboard
1. Go to your Railway project dashboard
2. Go to "Variables" tab
3. Add these variables:
   ```
   PORT=8000
   FLASK_ENV=production
   FLASK_APP=app.py
   PYTHONPATH=.
   ```

## 🐛 Debug Commands

If the deployment still fails, run these commands in Railway's console:

```bash
# Check environment
python debug_railway.py

# Test the app directly
python app.py

# Check PORT variable
echo "PORT is: $PORT"

# Manual start with explicit port
gunicorn app:app --bind 0.0.0.0:8000
```

## 📋 Checklist

- [ ] `requirements.txt` includes `gunicorn`
- [ ] `app.py` has correct port handling
- [ ] `Procfile` uses correct syntax
- [ ] Environment variables are set in Railway
- [ ] Latest code is pushed to GitHub

## 🔍 Common Issues and Solutions

### Issue 1: "$PORT is not a valid port number"
**Solution**: Use `${PORT:-8000}` syntax in Procfile

### Issue 2: "Application failed to respond"
**Solution**: Ensure app binds to `0.0.0.0`, not `localhost`

### Issue 3: "Module not found"
**Solution**: Check `requirements.txt` and set `PYTHONPATH=.`

### Issue 4: "Permission denied"
**Solution**: Ensure startup scripts are executable

## 📞 Next Steps

1. **Push the fixed code**:
   ```bash
   git add .
   git commit -m "Fix Railway deployment PORT issue"
   git push origin main
   ```

2. **Monitor deployment**:
   - Check Railway dashboard logs
   - Wait for deployment to complete
   - Test health endpoint

3. **Verify deployment**:
   ```bash
   curl https://web-production-152d1.up.railway.app/health
   ```

4. **If still failing**:
   - Check Railway logs in dashboard
   - Run debug script: `python debug_railway.py`
   - Contact Railway support or check this guide again

## 🎯 Expected Result

After applying these fixes, your API should be accessible at:
- **Health Check**: https://web-production-152d1.up.railway.app/health
- **API Endpoint**: https://web-production-152d1.up.railway.app/api/trades
- **Root**: https://web-production-152d1.up.railway.app/

The health endpoint should return:
```json
{
  "status": "healthy",
  "timestamp": "2025-08-02T..."
}
```
